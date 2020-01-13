# 1.What type of cars are most commonly rented?
select vehicle_type, round(count(vehicle_type)/(select count(*) from vehicles)*100,2) as 'Percent of Rentals'  from vehicles
group by vehicle_type;

# 2.What is the average duration and cost of rentals by car type?
select vehicle_type, datediff(EndDate, StartDate) as 'Average Duration', datediff(EndDate, StartDate)*PricePerDay as Cost
from rentals as r 
join vehicles as v on v.VID = r.VID
join finances as f 
on r.Order_ID = f.Order_ID
group by vehicle_type order by Cost desc;


# 3.On what day of the week do most rentals start?
select count(*) as 'Total Rentals', dayname(StartDate) as 'Day of the Week'from rentals
group by dayname(StartDate) order by count(*) desc;


# 3.On what day of the week do most rentals end?
select count(*) as 'Total Rentals', dayname(EndDate) as 'Day of the Week'from rentals
group by dayname(EndDate) order by count(*) desc;



#4 What are the states with the most competitive prices, and how do the reviews compare for a particular state?
Select h.hostState, avg(f.PricePerDay) as 'Average Price per day', round(avg(v.reviews),2) 
as 'Average Reviews' from host h
join rentals r on r.host_ID = h.hostID
join finances f on f.Order_ID = r.host_ID
join vehicles v on v.hostID = h.hostID
group by h.hostState
order by avg(f.PricePerDay) asc, round(avg(v.reviews)) desc limit 5;


#5 Who were the customers that had the most additional costs on their orders? 
Select r.Order_ID, c.FirstName, c.LastName, (MilesOverLimit*.75) as MilesOverLimit_Cost, r.ExtraCosts, 
f.miscCost, (r.MilesOverLimit*0.75 + r.ExtraCosts + f.miscCost) as TotalCosts from rentals r
join finances f on f.Order_ID = r.Order_ID
join customers c on c.customer_ID = r.Customer_ID 
group by Order_ID
order by TotalCosts desc;

#6 Sub query to calculate who is the most profitable host
Select h.hostID, h.firstName, h.lastName, h.hostState, h.vehicleCount,
f.PricePerDay*(r.EndDate - r.StartDate)+r.ExtraCosts+f.miscCost + (r.MilesOverLimit*.75) as TotalProfits from host h
join rentals r on r.host_ID = h.hostID
join finances f on f.Order_ID = r.Order_ID
group by h.hostID having TotalProfits =
(Select max(TotalProfits) from(
Select f.PricePerDay*(EndDate - StartDate)+ExtraCosts+miscCost + (r.MilesOverLimit*.75) as TotalProfits from rentals r
join finances f on f.Order_ID = r.Order_ID
order by PricePerDay*(EndDate - StartDate)+ExtraCosts+miscCost+(r.MilesOverLimit*.75) desc ) host);


#7 provide top-line metrics related to Turo’s host vehicle performance in each state
SELECT hostState, COUNT(h.hostID) as "# of Hosts", round(avg(vehicleCount)) as "Average # of Vehicles", round(avg(insurance)) as "Average Insurance Coverage", v.vehicle_type as "Most Common Vehicle Type", v.class as "Most Common Vehicle Class", round(avg(r.Deposit),2) as "Average Deposit Fee", round(avg(f.PricePerDay),2) as "Average Price per Day"
FROM `host` h
JOIN vehicles v on v.hostID = h.hostID
JOIN rentals r on r.host_ID = h.hostID 
JOIN finances f on f.Order_ID = r.Order_ID
GROUP BY hostState
ORDER BY COUNT(hostID) DESC;

#8 provides top-line metrics related to Turo’s customer rental performance in each state
SELECT CustState, COUNT(c.Customer_ID) as "# of Customers", round(avg(insurance)) as "Average Insurance Coverage", round(avg(v.mileage)/count(CustState),3) as "Average Miles Driven", round(avg(r.MilesOverLimit),3) as "Average Miles Over", r.Transport as "Most Common Delivery Method"
FROM customers c
JOIN rentals r on r.Customer_ID = c.Customer_ID
JOIN vehicles v on v.VID = r.VID
GROUP BY CustState
ORDER BY COUNT(Customer_ID) DESC;

#9 finds the average rental cost for a customer in each state
SELECT h.hostState, round(avg(f.PricePerDay) * avg(datediff(r.EndDate,r.StartDate))+ avg(r.ExtraCosts)+ avg(f.miscCost) + (avg(r.MilesOverLimit)*.75), 2) as "Average Rental Cost"
    FROM customers c
    JOIN rentals r ON c.Customer_ID = r.Customer_ID
    JOIN finances f ON f.Order_ID = r.Order_ID
    JOIN host h ON h.hostID = r.host_ID
    GROUP BY h.hostState;


#1 Stored procedure to calcualte the Total profit made by a cutomer in Turo
drop procedure if exists orderTotal;
DELIMITER //
Create procedure orderTotal(in custID INT, out profit DECIMAL(10,2))
Begin
	Set profit =
    (
    select f.PricePerDay*(r.EndDate - r.StartDate)+r.ExtraCosts+f.miscCost + (r.MilesOverLimit*.75)
    from customers c
    join rentals r on c.Customer_ID = r.Customer_ID
    join finances f on f.Order_ID = r.Order_ID
    where c.Customer_ID = custID
    );
end //
DELIMITER ;

call orderTotal(21, @profit);
Select @profit as 'Total Profit for cutomer 21';

#2 Creating a function to return the number of rentals for a given host ID
drop function if exists rentalCount;
delimiter //

create function rentalCount(hostID int) returns int(10)
deterministic 
begin

declare rentCount int(10);
set rentCount = (select count(*) from rentals where host_ID= hostid);
return (rentCount);
end //

delimiter ;

# 3 Creating a procedure to return the best performing vehicle class and the number of rentals
# for that class in a given month
drop procedure if exists countByMonth;
delimiter //

create procedure countByMonth (in currentMonth int, out vCount int(5), out vClass varchar(25))
begin

set vCount = 
 (
 select count(Order_ID)from vehicles as v
	join rentals as r
	on v.VID=r.VID
	where month(StartDate) = currentMonth and class = ( select class from vehicles as v
join rentals as r
on v.VID=r.VID
where month(StartDate)=currentMonth
group by class
order by count(Order_ID) desc limit 1)
 );
 set vClass =
 (
  select class from vehicles as v
join rentals as r
on v.VID=r.VID
where month(StartDate)=currentMonth
group by class
order by count(Order_ID) desc
limit 1
 );
 
end //

delimiter ;

call countByMonth(11, @vCount, @vClass);
select @vCount as 'Number of Vehicles', @vClass as 'Vehicle Class';


drop function if exists costlyHost;
delimiter //
# 4 Creating a function to find the total misc. cost for a given Host_ID.
create function costlyHost(hostid int) returns decimal(10,2)
deterministic 
begin
	declare costOfHost decimal(10,2);
    set costOfHost = 
    (select sum(miscCost) from finances as f join rentals as r
on f.Order_ID = r.Order_ID
where host_ID= hostid );
return (costOfHost);
end //

delimiter ; 

# Select statement using the two new UDFs
select distinct(hostID), costlyHost(hostID), rentalCount(hostID)
from `host` as h
join rentals as r
on h.hostID = r.host_ID
order by costlyHost(hostID) desc;

# Creating a function to return the number of rentals for a given host ID
drop function if exists rentalCount;
delimiter //

create function rentalCount(hostID int) returns int(10)
deterministic 
begin

declare rentCount int(10);
set rentCount = (select count(*) from rentals where host_ID= hostid);
return (rentCount);
end //

delimiter ;

#Finding the 10 most prolific hosts

select distinct(host_ID), rentalCount(host_ID) as 'Number of rentals' from rentals
order by rentalCount(host_ID) desc limit 10;


# Creating a trigger to enforce price minimum and maximum.
drop trigger if exists priceCap;
delimiter //

create trigger priceCap
before insert on finances
for each row
begin 
	case
    when new.PricePerDay >5000 then set new.PricePerDay = 5000;
    when new.PricePerDay <40 then set new.PricePerDay = 40;
    end case;
end //
delimiter ;







