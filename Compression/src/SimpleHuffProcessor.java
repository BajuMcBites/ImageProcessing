import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.SQLOutput;
import java.util.ArrayList;

public class SimpleHuffProcessor implements IHuffProcessor {

    // variables to store precompress method data
    private String[] codes;
    private TreeNode huffmanTree;
    private int headerFormat;
    private int bitsSaved;
    private int freqs[];
    private int nOfNodes;
    private int nOfLeaves;

    /**
     * Preprocess data so that compression is possible ---
     * count characters/create tree/store state so that
     * a subsequent call to compress will work. The InputStream
     * is <em>not</em> a BitInputStream, so wrap it int one as needed.
     * 
     * @param in           is the stream which could be subsequently compressed
     * @param headerFormat a constant from IHuffProcessor that determines what kind
     *                     of
     *                     header to use, standard count format, standard tree
     *                     format, or
     *                     possibly some format added in the future.
     * @return number of bits saved by compression or some other measure
     *         Note, to determine the number of
     *         bits saved, the number of bits written includes
     *         ALL bits that will be written including the
     *         magic number, the header format number, the header to
     *         reproduce the tree, AND the actual data.
     * @throws IOException if an error occurs while reading from the input file.
     */
    public int preprocessCompress(InputStream in, int headerFormat) throws IOException {
        freqs = readFile(in);

        Object[] result = HuffmanTree(freqs);

        huffmanTree = (TreeNode) result[0];
        int nOfLeaves = (int) result[1];
        int nOfNodes = (int) result[2];

        this.headerFormat = headerFormat;

        codes = new String[ALPH_SIZE + 1];
        getCodes(huffmanTree, codes, new StringBuilder());

        bitsSaved = 0;
        for (int i = 0; i < freqs.length; i++) {
            if (codes[i] != null) {
                int count = (BITS_PER_WORD - codes[i].length()) * freqs[i];
                bitsSaved += count;
            }
        }

        if (headerFormat == STORE_COUNTS) {
            bitsSaved -= Math.pow(2, BITS_PER_WORD) * BITS_PER_INT;
        } else if (headerFormat == STORE_TREE) {
            bitsSaved -= (BITS_PER_INT + nOfLeaves * (BITS_PER_WORD + 1) + nOfNodes);
        }

        // For EOF, Magic Number, Header Format Constant
        bitsSaved -= (codes[ALPH_SIZE].length() + BITS_PER_INT + BITS_PER_INT);
        return bitsSaved;
    }

    /**
     * from an array of frequencies, it constructs a huffman tree
     * 
     * @param freqs the array of frequencies
     * @return an object array containing the huffman tree in index 0, the number of
     *         leaves in index 1,
     *         and the number of nodes in index 2
     */
    private Object[] HuffmanTree(int[] freqs) {

        Object[] result = new Object[3];

        PriorityQueue q = new PriorityQueue();
        int index = 0;
        while (index < freqs.length) {
            if (freqs[index] != 0) {
                TreeNode temp = new TreeNode(index, freqs[index]);
                q.enqueue(temp);
            }
            index++;
        }

        TreeNode eof = new TreeNode(PSEUDO_EOF, 1);
        q.enqueue(eof);

        nOfLeaves = q.size();
        nOfNodes = nOfLeaves;

        while (q.size() > 1) {
            TreeNode left = q.dequeue();
            TreeNode right = q.dequeue();

            TreeNode temp = new TreeNode(left, -1, right);
            q.enqueue(temp);
            nOfNodes++;
        }
        result[0] = q.dequeue();
        result[1] = nOfLeaves;
        result[2] = nOfNodes;

        return result;
    }

    /**
     * recursive method using a huffmanTree to get all the nodes of the huffman tree
     * 
     * @param n     the current node being used
     * @param codes the array used to store the completed codes
     * @param sb    a string builder used to track the current path along the tree
     *              and use that
     *              to find the code for a given node
     */
    private void getCodes(TreeNode n, String[] codes, StringBuilder sb) {

        if (n.getValue() != -1) {
            codes[n.getValue()] = sb.toString();
        } else {

            sb.append(0);
            getCodes(n.getLeft(), codes, sb);
            sb.deleteCharAt(sb.length() - 1);

            sb.append(1);
            getCodes(n.getRight(), codes, sb);
            sb.deleteCharAt(sb.length() - 1);

        }
    }

    /**
     * This reads a file and counts the frequencies of the given 8 bit sets
     * 
     * @param in the file being read
     * @return an int array representing the frequencies of the 8 bit sections
     * @throws IOException
     */
    private int[] readFile(InputStream in) throws IOException {
        int[] freqs = new int[ALPH_SIZE];
        BitInputStream stream = new BitInputStream(in);
        int read = stream.readBits(BITS_PER_WORD);
        while (read != -1) {
            freqs[read]++;
            read = stream.readBits(BITS_PER_WORD);
        }

        return freqs;
    }

    /**
     * Compresses input to output, where the same InputStream has
     * previously been pre-processed via <code>preprocessCompress</code>
     * storing state used by this call.
     * <br>
     * pre: <code>preprocessCompress</code> must be called before this method
     * 
     * @param in    is the stream being compressed (NOT a BitInputStream)
     * @param out   is bound to a file/stream to which bits are written
     *              for the compressed file (not a BitOutputStream)
     * @param force if this is true create the output file even if it is larger than
     *              the input file.
     *              If this is false do not create the output file if it is larger
     *              than the input file.
     * @return the number of bits written.
     * @throws IOException if an error occurs while reading from the input file or
     *                     writing to the output file.
     */
    public int compress(InputStream in, OutputStream out, boolean force) throws IOException {

        if (bitsSaved < 0 && !force) {
            return 0;
        }

        BitInputStream bitIn = new BitInputStream(in);
        BitOutputStream bitOut = new BitOutputStream(out);

        int totalBits = writeHeaderInfo(bitOut);
        int read = bitIn.readBits(BITS_PER_WORD);

        while (read != -1) {
            bitOut.writeBits(codes[read].length(), Integer.parseInt(codes[read], 2));
            totalBits += codes[read].length();
            read = bitIn.readBits(BITS_PER_WORD);
        }

        bitOut.writeBits(codes[ALPH_SIZE].length(), Integer.parseInt(codes[ALPH_SIZE], 2));
        totalBits += codes[ALPH_SIZE].length();

        return totalBits;
    }

    /**
     * writes the header info at the top of the new compressed file
     * 
     * @param bitOut the file being written to
     * @return the number of bits written to the output file
     */
    private int writeHeaderInfo(BitOutputStream bitOut) {

        int totalBits = 0;

        bitOut.writeBits(BITS_PER_INT, MAGIC_NUMBER);
        bitOut.writeBits(BITS_PER_INT, headerFormat);
        totalBits += BITS_PER_INT * 2;

        if (headerFormat == STORE_COUNTS) {
            for (int freq : freqs) {
                bitOut.writeBits(BITS_PER_INT, freq);
            }

            totalBits += BITS_PER_INT * freqs.length;

        } else if (headerFormat == STORE_TREE) {

            bitOut.writeBits(BITS_PER_INT, nOfLeaves * (BITS_PER_WORD + 1) + nOfNodes);
            treeCompressTraversal(huffmanTree, bitOut);

            totalBits += BITS_PER_INT;
            totalBits += nOfLeaves * (BITS_PER_WORD + 1) + nOfNodes;

        }

        return totalBits;
    }

    /**
     * Recursive method to write a huffman tree into a given file
     * 
     * @param n   the current node being used
     * @param out the output file
     */
    private void treeCompressTraversal(TreeNode n, BitOutputStream out) {
        if (n.getValue() != -1) {
            out.writeBits(1, 1);
            out.writeBits(9, n.getValue());
        } else {
            out.writeBits(1, 0);
            treeCompressTraversal(n.getLeft(), out);
            treeCompressTraversal(n.getRight(), out);
        }
    }

    /**
     * Uncompress a previously compressed stream in, writing the
     * uncompressed bits/data to out.
     * 
     * @param in  is the previously compressed data (not a BitInputStream)
     * @param out is the uncompressed file/stream
     * @return the number of bits written to the uncompressed file/stream
     * @throws IOException if an error occurs while reading from the input file or
     *                     writing to the output file.
     */
    public int uncompress(InputStream in, OutputStream out) throws IOException {
        BitInputStream bitIn = new BitInputStream(in);
        BitOutputStream bitOut = new BitOutputStream(out);

        int read = bitIn.readBits(BITS_PER_INT);
        if (read != MAGIC_NUMBER) { // if not Huffman magic number first
            throw new IOException();
        }

        read = bitIn.readBits(BITS_PER_INT);
        if (read == STORE_COUNTS) {

            huffmanTree = huffTreeFromStore(bitIn);

        } else if (read == STORE_TREE) {

            read = bitIn.readBits(BITS_PER_INT); // Tree size (not used in rebuilding the tree)
            huffmanTree = rebuildTree(bitIn);

        } else {
            throw new IOException(); // Invalid format header
        }

        return decodeFile(bitIn, bitOut);

    }

    /**
     * Using the huffman tree stored in the instance of the class, and the input
     * file, it decodes
     * the compressed version of the file into the output file
     * 
     * @param bitIn  the input file
     * @param bitOut the output file
     * @return the number of bits being wriiten to the output file
     * @throws IOException
     */
    private int decodeFile(BitInputStream bitIn, BitOutputStream bitOut) throws IOException {

        TreeNode n = huffmanTree;

        boolean eof = false;
        int totalBits = 0;
        while (!eof) {
            if (n.getValue() != -1) {

                if (n.getValue() == PSEUDO_EOF) {
                    eof = true;
                } else {
                    bitOut.writeBits(BITS_PER_WORD, n.getValue());

                    totalBits += BITS_PER_WORD;
                    n = huffmanTree;
                }
            } else {
                int read = bitIn.readBits(1);
                if (read == 0) {
                    n = n.getLeft();
                } else if (read == 1) {
                    n = n.getRight();
                }
            }
        }
        return totalBits;
    }

    /**
     * creates a huffman tree from the intput file if the header is in the Store
     * Frequencies format
     * 
     * @param bitIn the input file
     * @return a treenode that is the root of a huffman tree
     * @throws IOException
     */
    private TreeNode huffTreeFromStore(BitInputStream bitIn) throws IOException {

        freqs = new int[ALPH_SIZE];

        for (int i = 0; i < ALPH_SIZE; i++) {
            int read = bitIn.readBits(BITS_PER_INT);
            freqs[i] = read;
        }
        return huffmanTree = (TreeNode) HuffmanTree(freqs)[0];

    }

    /**
     * recursive method that prints the values of a tree in a pre-order traversal
     * 
     * @param n the current node
     */
    private void printTree(TreeNode n) {
        if (n != null) {
            System.out.println(n.getValue());
            printTree(n.getLeft());
            printTree(n.getRight());
        }
    }

    /**
     * given the header format is in the Store Tree format, using the input file,
     * this method
     * recursively rebuilds the huffman Tree
     * 
     * @param bitIn the input file
     * @return a treeNode that is the root of a huffman Tree
     * @throws IOException
     */
    private TreeNode rebuildTree(BitInputStream bitIn) throws IOException {
        int read = bitIn.readBits(1);
        if (read == 1) {
            read = bitIn.readBits(9);
            return new TreeNode(read, 0);
        } else if (read == 0) {
            TreeNode tempLeft = rebuildTree(bitIn);
            TreeNode tempRight = rebuildTree(bitIn);
            return new TreeNode(tempLeft, -1, tempRight);
        } else {
            throw new IOException();
        }

    }

}
