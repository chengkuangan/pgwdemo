package blog.braindose.history;

import java.util.Date;

//@JsonIgnoreProperties(ignoreUnknown = true)
public class AccountProfile{

    //{"_id":"5db8d6eb1108741c233d9234","accountId":"20191029-MY-123456789","name":"Gan Cheng Kuan","age":43,"nationality":"Malaysian",
    //"address":"35, Jalan 3/2E, Setia Ecohill, 43500 Semenyih, Selangor, Malaysia.","lastUpdatedDate":1563178274158,"createdDate":1563178274158}
    public String _id;
    public String accountId;
    public String name;
    public int age;
    public String nationality;
    public String address;
    public long lastUpdatedDate;
    public long createdDate;

    public AccountProfile(){

    }

    
}