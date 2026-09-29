@isTest
public class CheckCarTest {
    @isTest
    static void test1(){
    CheckCar.prepareForDrive();
    system.AssertEquals(CarManager.engineStatus,'ON');
    }
 
}