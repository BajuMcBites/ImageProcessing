import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class Runner {
    public static void main(String[] args)throws IOException {
        
        String compressFileIn = "TEMPFILE";
        String compressFileOut = "TEMPFILE";

        // String decompressFileIn = "TEMPFILE";
        // String decompressFileOut = "TEMPFILE";


        InputStream compressIn = new BitInputStream(compressFileIn);
        OutputStream compressOut = new BitOutputStream(compressFileOut);

        // InputStream decompressIn = new BitInputStream(decompressFileIn);
        // OutputStream decompressOut = new BitOutputStream(decompressFileOut);
        
        SimpleHuffProcessor huff = new SimpleHuffProcessor();

        huff.preprocessCompress(compressIn, IHuffConstants.STORE_TREE);
        huff.compress(compressIn, compressOut, true);

        // huff.uncompress(decompressIn, decompressOut);

    }
}
