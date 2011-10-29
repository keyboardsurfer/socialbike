package org.cbase.dev.adkbike.app;

import java.io.FileDescriptor;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

import org.cbase.dev.adkbike.R;

import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;

import android.app.Activity;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;


public class SocialBikeActivity extends Activity implements Runnable,
		OnClickListener {

	private static final String TAG = SocialBikeActivity.class.getSimpleName();

	private static final String ACTION_USB_PERMISSION = "org.cbase.dev.adkbike.action.USB_PERMISSION";

	private UsbManager mUsbManager;
	private PendingIntent mPermissionIntent;
	private boolean mPermissionRequestPending;

	private Button lockButton;
	private boolean locked;

	UsbAccessory mAccessory;
	ParcelFileDescriptor mFileDescriptor;
	FileInputStream mInputStream;
	FileOutputStream mOutputStream;

	/**
	 * The command that indicates that we're sending a key to the lock.
	 */
	public static final byte COMMAND_KEY = 1;
	/**
	 * The command that indicates that we want to close the lock.
	 */
	public static final byte COMMAND_LOCK = 2;
	/**
	 * The command that indicates that we want to open the lock.
	 */
	public static final byte COMMAND_UNLOCK = 3;

	/**
	 * Indicates that you want to talk to the shackle feeler.
	 */
	public static final byte COMMAND_SHACKLE_FEELER = 4;

	/**
	 * The command that indicates that we want to change the lights attached to
	 * the lock (if any)
	 */
	public static final byte COMMAND_LIGHT = 5;

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

	/** Called when the activity is first created. */
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

//		Intent intent = getIntent();
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
			Log.d(TAG, "mAccessory is null");
		}
	}

	private void openAccessory(UsbAccessory accessory) {
		mFileDescriptor = mUsbManager.openAccessory(accessory);
		if (mFileDescriptor != null) {
			mAccessory = accessory;
			FileDescriptor fd = mFileDescriptor.getFileDescriptor();
			mInputStream = new FileInputStream(fd);
			mOutputStream = new FileOutputStream(fd);
			Thread thread = new Thread(null, this, "SocialBike");
			thread.start();
			Log.d(TAG, "accessory opened");
			toggleControls(true);
		} else {
			Log.d(TAG, "accessory open fail");
		}
	}

	private void closeAccessory() {
		toggleControls(false);

		try {
			if (mFileDescriptor != null) {
				mFileDescriptor.close();
			}
		} catch (IOException e) {
		} finally {
			mFileDescriptor = null;
			mAccessory = null;
		}
	}

	private void toggleControls(boolean enabled) {
		findViewById(R.id.toggleLock).setEnabled(enabled);
	}

	/**
	 * Sends a command to the attached device.
	 * 
	 * @param command
	 *            The command you want to send.
	 * @param target
	 * @param value
	 *            The value that should be sent.
	 */
	public void sendCommand(byte command, byte target, int value) {
		byte[] buffer = new byte[3];
		if (value > 255)
			value = 255;

		buffer[0] = command;
		buffer[1] = target;
		buffer[2] = (byte) value;
		Log.d(TAG, "stream is: " + mOutputStream.toString());
		Log.d(TAG, "buffer[0] is:" + buffer[0]);
		Log.d(TAG, "buffer[1] is:" + buffer[1]);
		Log.d(TAG, "buffer[2] is:" + buffer[2]);
		if (mOutputStream != null && buffer[1] != -1) {
			try {
				mOutputStream.write(buffer);
				Log.i(TAG, "Wrote to adk");
			} catch (IOException e) {
				Log.e(TAG, "write failed", e);
			}
		}
	}

	@Override
	public void run() {
		// TODO Auto-generated method stub
	}

	@Override
	public void onClick(View v) {
		switch (v.getId()) {
		case R.id.toggleLock:
			if (locked) {
				sendCommand(COMMAND_UNLOCK, (byte) COMMAND_UNLOCK, 1);
				lockButton.setText(R.string.lock);
			} else {
				sendCommand(COMMAND_LOCK, (byte) COMMAND_LOCK, 1);
				lockButton.setText(R.string.unlock);
			}
			locked = !locked;
			break;

		default:
			break;
		}
	}

}
