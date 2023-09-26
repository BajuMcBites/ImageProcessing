import java.util.Iterator;
import java.util.LinkedList;

public class PriorityQueue {

    private LinkedList<TreeNode> con; // storage container

    public PriorityQueue() {
        con = new LinkedList<>();
    } // constructor

    /**
     * adds the tree node n in the correct spot in the priority queue
     * 
     * @param n the node being added
     */
    public void enqueue(TreeNode n) {
        int index = 0;
        Iterator<TreeNode> it = con.iterator();

        while (it.hasNext() && n.compareTo(it.next()) >= 0) {
            index++;
        }

        con.add(index, n);
    }

    /**
     * Removes the first element in the priority queue and returns it
     * 
     * @return the first element in the priority queue
     */
    public TreeNode dequeue() {
        return con.remove(0);
    }

    /**
     * gives the number of elements in the priority queue
     * 
     * @return the size of the priority queue
     */
    public int size() {
        return con.size();
    }

}
