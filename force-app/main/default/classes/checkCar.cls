public class checkCar {
  public static void prepareForDrive() 
  {
        CarManager.startEngine(); 
        System.debug('Current status is: ' + CarManager.engineStatus);
    }
}