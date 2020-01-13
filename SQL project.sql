select version();

create database _team_26_turo;
use _team26_turo;

create table if not exists Customers (
	Customer_ID int not null,
    FirstName varchar(30) not null,
    LastName varchar(50) not null,
    EmailAddress varchar(50) null,
    Date_of_Birth date not null,
    Facebook_id varchar(50) null,
    Twitter_id varchar(50) null,
    CustState varchar(10) not null,
    reviews int null,
    insurance int not null,
    phone_number bigint (15) null,
    lastModified timestamp,
    primary key (Customer_ID)
    );
    
    create table if not exists Rentals (
	Order_ID int not null,
    Customer_ID int not null,
    host_ID int not null,
    StartDate date not null,
    EndDate date not null,
    VID int not null,
    MilesOverLimit decimal (10,2),
    Transport varchar(10) not null check (Transport in ('Pickup, Delivery')),
    Deposit int not null,
    ExtraCosts decimal (10,2),
    foreign key(Customer_ID) references customers(Customer_ID),
    foreign key (host_ID) references host(hostID),
    foreign key (VID) references vehicles(VID), 
    primary key (Order_ID)
    );
    
DROP TABLE IF EXISTS `host`;

CREATE TABLE IF NOT EXISTS `host` (
`hostID` INT NOT NULL,
`firstName` VARCHAR(45) NOT NULL,
`lastName` VARCHAR(45) NOT NULL,
`email` VARCHAR(45) NOT NULL,
`birthDate` DATE NOT NULL,
`phone` BIGINT(15) NULL,
`street1` VARCHAR(100) NOT NULL,
`createDate` DATE NOT NULL,
`vehicleCount` INT NOT NULL,
`insurance` INT NOT NULL,
PRIMARY KEY (`hostID`));


create table vehicles (
	VID int unique not null,
    vehicle_type varchar(20) not null,
    price decimal(5,2) not null,
    trips int,
    year int not null,
    mileage int not null,
    reviews decimal (2,2),
    capacity int not null,
    hostID int not null,
    trasmission_type varchar(15),
    class varchar(20) not null,
    primary key (VID),
    foreign key (hostID) references host(hostID)
    );

Alter table rentals modify column Deposit decimal(10,2);

create table finances(
Fin_ID int unique not null,
Order_ID int unique not null,
PricePerDay decimal(10,2) not null,
TransactionDate date not null,
miscCost decimal(10,2),
primary key (Fin_ID),
foreign key (Order_ID) references rentals(Order_ID)
);




