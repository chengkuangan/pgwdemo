package com.gck.demo.paymentgateway.reconcile.connect;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.HttpURLConnection;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import com.fasterxml.jackson.databind.ObjectMapper;

public class WebService {

    public String get(String address) {
        return request(address, "GET");
    }

    public void post(String address, String content) {
        send(address, "POST", content);
    }

    public void put(String address, String content) {
        send(address, "PUT", content);
    }

    public String request(String address, String method) {

        StringBuffer resp = new StringBuffer();

        try {

            URL url = new URL(address);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod(method);
            conn.setRequestProperty("Accept", "application/json");

            if (conn.getResponseCode() != 200) {
                throw new RuntimeException("Failed : HTTP error code : " + conn.getResponseCode());
            }

            BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));

            String output;
            System.out.println("Output from Server .... \n");
            while ((output = br.readLine()) != null) {
                resp.append(output);
                System.out.println(output);
            }

            conn.disconnect();

            return resp.toString();

        } catch (MalformedURLException e) {
            throw new RuntimeException("Failed : " + e.getMessage());
        } catch (IOException e) {
            throw new RuntimeException("Failed : " + e.getMessage());
        }
    }

    public void send(String adddress, String method, String content) {
        try {
            URL url = new URL(adddress);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setDoOutput(true);
            conn.setRequestMethod(method);
            conn.setRequestProperty("Content-Type", "application/json");

            OutputStream os = conn.getOutputStream();
            os.write(content.getBytes());
            os.flush();

            if (conn.getResponseCode() != HttpURLConnection.HTTP_OK) {
                throw new RuntimeException("Failed : HTTP error code : " + conn.getResponseCode());
            }

            BufferedReader br = new BufferedReader(new InputStreamReader((conn.getInputStream())));

            String output;
            System.out.println("Output from Server .... \n");
            
            while ((output = br.readLine()) != null) {
                System.out.println(output);
            }

            conn.disconnect();

        } catch (MalformedURLException e) {
                throw new RuntimeException("Failed : " + e.getMessage());
        } catch (IOException e) {
                throw new RuntimeException("Failed : " + e.getMessage());
        }
    }
}
