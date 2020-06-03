package com.gck.demo.paymentgateway.reconcile.models;
import java.util.Date;

public class CreditResponse{

    private String creditRecordId;
    private String sourceAccountRecordId;
    private String targetAccountRecordId;
    private String sourceAccountId;
    private String targetAccountId;
    private double creditAmount;
    private double targetAccountBalance;
    private double sourceAccountBalance;
    private Date transactionDate;
    
    /**
     * @return String return the creditRecordId
     */
    public String getCreditRecordId() {
        return creditRecordId;
    }

    /**
     * @param creditRecordId the creditRecordId to set
     */
    public void setCreditRecordId(String creditRecordId) {
        this.creditRecordId = creditRecordId;
    }

    /**
     * @return String return the sourceAccountRecordId
     */
    public String getSourceAccountRecordId() {
        return sourceAccountRecordId;
    }

    /**
     * @param sourceAccountRecordId the sourceAccountRecordId to set
     */
    public void setSourceAccountRecordId(String sourceAccountRecordId) {
        this.sourceAccountRecordId = sourceAccountRecordId;
    }

    /**
     * @return String return the targetAccountRecordId
     */
    public String getTargetAccountRecordId() {
        return targetAccountRecordId;
    }

    /**
     * @param targetAccountRecordId the targetAccountRecordId to set
     */
    public void setTargetAccountRecordId(String targetAccountRecordId) {
        this.targetAccountRecordId = targetAccountRecordId;
    }

    /**
     * @return String return the sourceAccountId
     */
    public String getSourceAccountId() {
        return sourceAccountId;
    }

    /**
     * @param sourceAccountId the sourceAccountId to set
     */
    public void setSourceAccountId(String sourceAccountId) {
        this.sourceAccountId = sourceAccountId;
    }

    /**
     * @return String return the targetAccountId
     */
    public String getTargetAccountId() {
        return targetAccountId;
    }

    /**
     * @param targetAccountId the targetAccountId to set
     */
    public void setTargetAccountId(String targetAccountId) {
        this.targetAccountId = targetAccountId;
    }

    /**
     * @return double return the creditAmount
     */
    public double getCreditAmount() {
        return creditAmount;
    }

    /**
     * @param creditAmount the creditAmount to set
     */
    public void setCreditAmount(double creditAmount) {
        this.creditAmount = creditAmount;
    }

    /**
     * @return double return the targetAccountBalance
     */
    public double getTargetAccountBalance() {
        return targetAccountBalance;
    }

    /**
     * @param targetAccountBalance the targetAccountBalance to set
     */
    public void setTargetAccountBalance(double targetAccountBalance) {
        this.targetAccountBalance = targetAccountBalance;
    }

    /**
     * @return double return the sourceAccountBalance
     */
    public double getSourceAccountBalance() {
        return sourceAccountBalance;
    }

    /**
     * @param sourceAccountBalance the sourceAccountBalance to set
     */
    public void setSourceAccountBalance(double sourceAccountBalance) {
        this.sourceAccountBalance = sourceAccountBalance;
    }

    /**
     * @return Date return the transactionDate
     */
    public Date getTransactionDate() {
        return transactionDate;
    }

    /**
     * @param transactionDate the transactionDate to set
     */
    public void setTransactionDate(Date transactionDate) {
        this.transactionDate = transactionDate;
    }

}