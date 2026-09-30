public class GameController {

    public Integer highScore { get; set; }

    public GameController() {
        highScore = 0;
    }

    public void updateHighScore(Integer score) {
        if(score > highScore) {
            highScore = score;
        }
    }
}