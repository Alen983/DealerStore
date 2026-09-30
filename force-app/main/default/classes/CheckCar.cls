public class CheckCar {

   public static void prepareForDrive() {

        CarManager.startEngine(); 

        System.debug('Current status is: ' + CarManager.engineStatus);

    }

}