package org.cbase.dev.adkbike.app;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import org.cbase.dev.adkbike.R;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;
import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;

public class SocialBikeActivity extends Activity implements Runnable,
                                                            OnClickListener {

  private static final String TAG = SocialBikeActivity.class.getSimpleName();

  private static final String ACTION_USB_PERMISSION = "org.cbase.dev.adkbike.action.USB_PERMISSION";

  private UsbManager    mUsbManager;
  private PendingIntent mPermissionIntent;
  private boolean       mPermissionRequestPending;

  private Button  lockButton;
  private boolean locked;
  private boolean controlsEnabled = true;
  private SharedPreferences prefs;

  private String key;

  private UsbAccessory         mAccessory;
  private ParcelFileDescriptor mFileDescriptor;
  private FileInputStream      mInputStream;
  private FileOutputStream     mOutputStream;
  private Thread thread = new Thread(this, "LockThreadMartin");

  Handler handler = new Handler();

  /**
   * The command that indicates that we're sending a key to the lock.
   */
  public static final byte COMMAND_KEY  = 1;
  /**
   * The command that indicates that we want to close the lock.
   */
  public static final byte COMMAND_LOCK = 2;
  /**
   * Indicates unlock status
   * 1 indicates success
   * 0 indicates wrong password
   */
  public static final byte ANSWER_LOCK  = 2;

  /**
   * The command that indicates that we want to open the lock.
   */
  public static final byte COMMAND_UNLOCK        = 3;
  /**
   * Indicates unlock status
   * 1 indicates success
   * 0 indicates wrong password
   */
  public static final byte ANSWER_UNLOCK         = 3;
  /**
   * Indicates that you want to know whether the lock is open or closed.
   */
  public static final byte COMMAND_LOCK_STATUS   = 4;
  public static final byte ANSWER_LOCK_STATUS    = 4;
  /**
   * Tells you the status of the shackle, ie. if it's plugged or unplugged.
   */
  public static final byte ANSWER_SHACKLE_FEELER = 5;
  /**
   * The command that sets the new key
   * first 4 bytes masterkey, then 4 bytes new key
   */
  public static final byte COMMAND_SET_KEY       = 6;
  public static final byte ANSWER_SET_KEY        = 6;


  protected class KeyMessage {
    private byte sw;
    private byte key;

    public KeyMessage(byte sw, byte key) {
      this.sw = sw;
      this.key = key;
    }

    public byte getSw() {
      return sw;
    }

    public byte getKey() {
      return key;
    }
  }

  private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      if (ACTION_USB_PERMISSION.equals(action)) {
        synchronized (this) {
          UsbAccessory accessory = UsbManager.getAccessory(intent);
          if (intent.getBooleanExtra(
            UsbManager.EXTRA_PERMISSION_GRANTED, false)) {
            openAccessory(accessory);
          } else {
            Log.d(TAG, "permission denied for accessory "
                       + accessory);
          }
          mPermissionRequestPending = false;
        }
      } else if (UsbManager.ACTION_USB_ACCESSORY_DETACHED.equals(action)) {
        UsbAccessory accessory = UsbManager.getAccessory(intent);
        if (accessory != null && accessory.equals(mAccessory)) {
          closeAccessory();
        }
      }
    }
  };

  /**
   * Called when the activity is first created.
   */
  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    mUsbManager = UsbManager.getInstance(this);
    mPermissionIntent = PendingIntent.getBroadcast(this, 0, new Intent(
      ACTION_USB_PERMISSION), 0);
    IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);
    filter.addAction(UsbManager.ACTION_USB_ACCESSORY_DETACHED);
    registerReceiver(mUsbReceiver, filter);

    if (getLastNonConfigurationInstance() != null) {
      mAccessory = (UsbAccessory) getLastNonConfigurationInstance();
      openAccessory(mAccessory);
    }

    setContentView(R.layout.main);
    lockButton = (Button) findViewById(R.id.toggleLock);
    lockButton.setOnClickListener(this);
  }

  @Override
  public void onResume() {
    super.onResume();


    SharedPreferences prefs = PreferenceManager
      .getDefaultSharedPreferences(this);
    String prefKey = getString(R.string.preference_key);
    key = prefs.getString(prefKey, "");

    if (mInputStream != null && mOutputStream != null) {
      return;
    }

    UsbAccessory[] accessories = mUsbManager.getAccessoryList();
    UsbAccessory accessory = (accessories == null ? null : accessories[0]);
    if (accessory != null) {
      if (mUsbManager.hasPermission(accessory)) {
        openAccessory(accessory);
      } else {
        synchronized (mUsbReceiver) {
          if (!mPermissionRequestPending) {
            mUsbManager.requestPermission(accessory,
                                          mPermissionIntent);
            mPermissionRequestPending = true;
          }
        }
      }
    } else {
      toggleControls(false);
      Log.d(TAG, "mAccessory is null");
    }

  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (mUsbReceiver != null) {
      unregisterReceiver(mUsbReceiver);
    }
  }

  private void openAccessory(UsbAccessory accessory) {
    mFileDescriptor = mUsbManager.openAccessory(accessory);
    if (mFileDescriptor != null) {
      mAccessory = accessory;
      FileDescriptor fd = mFileDescriptor.getFileDescriptor();
      mInputStream = new FileInputStream(fd);
      mOutputStream = new FileOutputStream(fd);
      thread.start();
      Log.d(TAG, "accessory opened");
      toggleControls(true);
      sendCommand(COMMAND_LOCK_STATUS, 1);

//      sendCommand(COMMAND_LOCK_STATUS, 1, "1234");

    } else {
      Log.d(TAG, "accessory open fail");
    }

  }

  private void closeAccessory() {
    toggleControls(false);
    thread.stop();
    try {
      if (mFileDescriptor != null) {
        mFileDescriptor.close();
      }
    } catch (IOException e) {
    } finally {
      mFileDescriptor = null;
      mAccessory = null;
    }
    if (mOutputStream != null) {
      try {
        mOutputStream.close();
      } catch (IOException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
      }
    }
    if (mInputStream != null) {
      try {
        mInputStream.close();
      } catch (IOException e) {
        e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
      }
    }
    finish();
  }

  private void toggleControls(boolean enabled) {
    if (controlsEnabled != enabled) {
      lockButton.setEnabled(enabled);
      controlsEnabled = enabled;
    }
//    myToast("Controls enabled: " + enabled);
  }

  private void setKeyStatusReport(boolean b) {
    if (b) {
      myToast("Wrong Master Key");
    } else {
      myToast("Right Master Key");
    }
  }

  private void unlockStatusReport(boolean answer) {
    if (answer) {
      myToast("Wrong Key");
      setLocked(true);
    } else {
      setLocked(false);
      myToast("Right Key");
    }

  }

  private void lockStatusReport(boolean answer) {
    if (answer) {
      myToast("Not Locked");
    } else {
      setLocked(true);
      myToast("Locked");
    }

  }

  private void setLocked(boolean locked) {

    this.locked = locked;
    if (locked) {
      handler.post(new Runnable() {

        @Override
        public void run() {
          lockButton.setText(R.string.unlock);
        }
      });

    } else {

      handler.post(new Runnable() {

        @Override
        public void run() {
          lockButton.setText(R.string.lock);
        }
      });

    }
//    myToast("Locked is: " + locked);
  }

  /**
   * Sends a command to the attached device.
   *
   * @param command The command you want to send.
   * @param value   The value that should be sent.
   */
  public void sendCommand(byte command, int value) {
    byte[] buffer;
    buffer = new byte[16];
    if (value > 255)
      value = 255;

    buffer[0] = command;
    buffer[1] = 3;
    buffer[2] = (byte) value;

    writeBufferToAdk(command, buffer);
  }

  private byte[] keyStringToByteArray(String key) {
  	if (key.length() < 4) {
      return new byte[] {0,0,0,0};
    }
    return key.substring(0, 4).getBytes();
  }

  public void sendCommand(byte command, int value, String key) {
    byte[] buffer;
    buffer = new byte[16];
    if (key != null) {
      byte[] keyBytes = keyStringToByteArray(key);
      for (int i = 0; i < keyBytes.length; i++) {
        buffer[i + 2] = keyBytes[i];
      }
    }

    if (value > 255)
      value = 255;

    buffer[0] = command;
    buffer[1] = 6;


    writeBufferToAdk(command, buffer);
  }

  /**
   * ungetested
   *
   * @param command
   * @param value
   * @param key
   * @param masterKey
   */
  public void sendCommand(byte command, int value, String key, String masterKey) {
    byte[] buffer;
    buffer = new byte[16];
    if (key != null) {
      byte[] masterKeyBytes = keyStringToByteArray(masterKey);
      for (int i = 0; i < masterKeyBytes.length; i++) {
        buffer[i + 2] = masterKeyBytes[i];
      }
      byte[] keyBytes = keyStringToByteArray(key);
      for (int i = 0; i < keyBytes.length; i++) {
        buffer[i + 2 + 4] = keyBytes[i];
      }
    }

    if (value > 255)
      value = 255;

    buffer[0] = command;
    buffer[1] = 10;

    writeBufferToAdk(command, buffer);
  }

  private void writeBufferToAdk(byte command, byte[] buffer) {

    Log.d(TAG, "buffer[0] is:" + buffer[0]);
    Log.d(TAG, "buffer[1] is:" + buffer[1]);
    Log.d(TAG, "buffer[2] is:" + buffer[2]);
    Log.d(TAG, "buffer[3] is:" + buffer[3]);
    Log.d(TAG, "buffer[4] is:" + buffer[4]);
    Log.d(TAG, "buffer[5] is:" + buffer[5]);
    Log.d(TAG, "buffer[6] is:" + buffer[6]);
    Log.d(TAG, "buffer[7] is:" + buffer[7]);
    Log.d(TAG, "buffer[8] is:" + buffer[8]);
    Log.d(TAG, "buffer[9] is:" + buffer[9]);
    Log.d(TAG, "buffer[10] is:" + buffer[10]);
    Log.d(TAG, "buffer[11] is:" + buffer[11]);
    Log.d(TAG, "buffer[12] is:" + buffer[12]);
    Log.d(TAG, "buffer[13] is:" + buffer[13]);
    Log.d(TAG, "buffer[14] is:" + buffer[14]);
    Log.d(TAG, "buffer[15] is:" + buffer[15]);

    if (mOutputStream != null && buffer[1] != -1) {
      try {

        mOutputStream.write(buffer);
        mOutputStream.flush();
        Log.i(TAG, "Wrote to adk");

      } catch (IOException e) {
//        myToast("Write failed, please retry");
//        if (command == COMMAND_LOCK) {
//          setLocked(!locked);
//        }
        Log.e(TAG, "write failed", e);
      }
    } else {
//      myToast("OutputStream is null ||¬†command -1");
    }
  }

  /* Receive data from the lock */
  public void myToast(final String msg) {
    handler.post(new Runnable() {

      @Override
      public void run() {
        Toast.makeText(SocialBikeActivity.this, msg, Toast.LENGTH_SHORT).show();
      }
    });
  }

  @Override
  public void run() {
    Looper.prepare();
    int ret = 0;
    byte[] buffer = new byte[3];

    while (ret >= 0) {
      try {

        ret = mInputStream.read(buffer);
        Log.d(TAG, "ret: " + ret);
        for (int i = 0; i < ret; i++) {
          Log.d(TAG, "ret: buffer[" + i + "]" + buffer[i]);
        }
      } catch (IOException e) {
        break;
      }
      switch (buffer[0]) {
        case ANSWER_LOCK_STATUS: // 4
          // 1 is locked, else is open
          setLocked(buffer[1] == 1);
//          myToast("ANSWER_LOCK_STATUS: " + buffer[1]);
          break;
        case ANSWER_SHACKLE_FEELER: // 5
          // 0 is not plugged in, else is plugged in
          toggleControls(buffer[1] != 0);
          break;
        case ANSWER_UNLOCK: // 3
          // 0 wrong key
          // 1 locked
          unlockStatusReport(buffer[1] == 0);
          break;
        case ANSWER_LOCK: // 2
          // 1 locked
          lockStatusReport(buffer[1] == 0);
          break;
        case ANSWER_SET_KEY: // 6
          // 0 is not plugged in, else is plugged in
          setKeyStatusReport(buffer[1] != 0);
          break;
        default:
          Log.d(TAG, "unknown msg: " + buffer[0]);
//          Toast.makeText(this, "unknown msg", Toast.LENGTH_SHORT).show();
          break;
      }
    }
    Looper.loop();
  }

  @Override
  public void onClick(View v) {
    switch (v.getId()) {
      case R.id.toggleLock:
        if (locked) {
          sendCommand(COMMAND_UNLOCK, 1, key);
        } else {
          sendCommand(COMMAND_LOCK, 1);
        }
        setLocked(!locked);
        break;
      default:
        break;
    }
  }

  public boolean onCreateOptionsMenu(Menu menu) {
    super.onCreateOptionsMenu(menu);
    Log.d(TAG, "onCreateOptionsMenu");

    MenuInflater inflater = getMenuInflater();
    inflater.inflate(R.menu.main, menu);

    return true;
  }

  public boolean onOptionsItemSelected(MenuItem item) {
    super.onOptionsItemSelected(item);

    switch (item.getItemId()) {

      case R.id.preferences:
        startActivity(new Intent(this, Preferences.class));

        return true;

    }

    return false;
  }
}
