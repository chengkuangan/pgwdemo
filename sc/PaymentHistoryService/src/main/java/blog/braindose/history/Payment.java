package blog.braindose.history;

import java.util.Date;
import java.util.Locale;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public class Payment{

    //@JsonIgnore
    //public Object _id;
    public String id;
    public long date;
    public String sourceAccount;
    public String sourceAccountName;
    public String targetAccount;
    public String targetAccountName;
    public String participateAccount;
    public String participateAccountName;
    public String action;
    public double amount;
    public double sourceAccountBalance;
    //Locale loc = new Locale("en", "US");
    DateFormat dateFormat = new SimpleDateFormat("dd/MM/yyyy hh:mm:ss a");

    public Payment(){

    }

    public Payment(String id, long date, String sourceAccount, String targetAccount, double amount, double sourceAccountBalance){
        this.id = id;
        this.date = date;
        this.targetAccount = targetAccount;
        this.sourceAccount = sourceAccount;
        this.amount = amount;
        this.sourceAccountBalance = sourceAccountBalance;
    }

    public Payment(long date, String sourceAccount, String targetAccount, double amount, double sourceAccountBalance, String participateAccount, String action){
        this.date = date;
        this.targetAccount = targetAccount;
        this.sourceAccount = sourceAccount;
        this.amount = amount;
        this.sourceAccountBalance = sourceAccountBalance;
        this.participateAccount = participateAccount;
        this.action = action;
    }

    public String getDateString(){
        return dateFormat.format(new Date(this.date));
    }
}