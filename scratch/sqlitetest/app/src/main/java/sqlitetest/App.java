/*
 * This Java source file was generated by the Gradle 'init' task.
 */
package sqlitetest;

import java.lang.Thread;
import java.sql.*;

public class App {
    private static Connection conn;

    public static Connection getConn() throws SQLException {
        if (conn == null || conn.isClosed()) {
            System.out.println("creating database connection");
            conn = DriverManager.getConnection("jdbc:sqlite:./test.db");
        }
        return conn;
    }

    public static void main(String[] args) {
        try {
            for (int i = 0; i < 1000000; i++) {
                System.out.printf("iteration %d\n", i);
                try {
                    System.out.println("1");
                    try (var preparedStatement = getConn().prepareStatement("INSERT OR REPLACE INTO test VALUES(?)")) {
                        preparedStatement.setInt(1, i);
                        preparedStatement.executeUpdate();
                    }
                    System.out.println("2");
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
