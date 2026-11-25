import java.io.File;
import java.nio.ByteBuffer;
import java.util.concurrent.atomic.AtomicInteger;
import uk.co.caprica.vlcj.factory.MediaPlayerFactory;
import uk.co.caprica.vlcj.player.base.MediaPlayer;
import uk.co.caprica.vlcj.player.base.State;
import uk.co.caprica.vlcj.player.embedded.EmbeddedMediaPlayer;
import uk.co.caprica.vlcj.player.embedded.videosurface.callback.BufferFormat;
import uk.co.caprica.vlcj.player.embedded.videosurface.callback.BufferFormatCallback;
import uk.co.caprica.vlcj.player.embedded.videosurface.callback.RenderCallback;
import uk.co.caprica.vlcj.player.embedded.videosurface.callback.format.RV32BufferFormat;

public class VlcAppTest {
  private static final int MIN_FRAMES = 10;
  private static final long TIMEOUT_MS = 20000;
  private static final long POLL_MS = 100;

  public static void main(String[] args) throws Exception {
    File vlcDir = new File(args[0]);
    System.setProperty("jna.library.path", vlcDir.getAbsolutePath());
    if (System.getProperty("os.name").startsWith("Windows")) {
      System.load(new File(vlcDir, "libvlccore.dll").getAbsolutePath());
      System.load(new File(vlcDir, "libvlc.dll").getAbsolutePath());
    }
    String vlcArgs = System.getProperty("vlc.args", "");
    MediaPlayerFactory factory = vlcArgs.isEmpty() ? new MediaPlayerFactory() : new MediaPlayerFactory(vlcArgs.split(" "));    System.out.println("libVLC " + factory.application().version());
    int failures = 0;
    for (int i = 1; i < args.length; i++) {
      if (!play(factory, args[i])) failures++;
    }
    factory.release();
    System.out.println(failures + " failures");
    System.exit(failures == 0 ? 0 : 1);
  }

  private static boolean play(MediaPlayerFactory factory, String path) throws InterruptedException {
    EmbeddedMediaPlayer player = factory.mediaPlayers().newEmbeddedMediaPlayer();
    AtomicInteger frames = new AtomicInteger();
    int[] size = new int[2];
    BufferFormatCallback format = new BufferFormatCallback() {
      @Override
      public BufferFormat getBufferFormat(int width, int height) {
        size[0] = width;
        size[1] = height;
        return new RV32BufferFormat(width, height);
      }

      @Override
      public void allocatedBuffers(ByteBuffer[] buffers) {}
    };
    RenderCallback render = (MediaPlayer mediaPlayer, ByteBuffer[] buffers, BufferFormat bufferFormat) -> frames.incrementAndGet();
    player.videoSurface().set(factory.videoSurfaces().newVideoSurface(format, render, true));
    player.media().play(path);
    long deadline = System.currentTimeMillis() + TIMEOUT_MS;
    State state = player.status().state();
    long time = player.status().time();
    while ((frames.get() < MIN_FRAMES || time <= 0) && System.currentTimeMillis() < deadline && state != State.ERROR && state != State.ENDED) {
      Thread.sleep(POLL_MS);
      state = player.status().state();
      time = player.status().time();
    }
    boolean played = frames.get() >= MIN_FRAMES && time > 0;
    System.out.printf("%s %s: %d frames of %dx%d, position %d ms, state %s, tracks %s%n",
      played ? "PASS" : "FAIL", new File(path).getName(), frames.get(), size[0], size[1], time, state, player.media().info().videoTracks());
    player.controls().stop();
    player.release();
    return played;
  }
}
