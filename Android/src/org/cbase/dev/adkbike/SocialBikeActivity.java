package org.cbase.dev.adkbike;

import java.io.FileInputStream;
import java.io.FileOutputStream;

import android.app.Activity;
import android.app.PendingIntent;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;

import com.android.future.usb.UsbAccessory;
import com.android.future.usb.UsbManager;

public class SocialBikeActivity extends Activity {

	private static final String ACTION_USB_PERMISSION = "com.google.android.DemoKit.action.USB_PERMISSION";

	private UsbManager mUsbManager;
	private PendingIntent mPermissionIntent;
	private boolean mPermissionRequestPending;

	UsbAccessory mAccessory;
	ParcelFileDescriptor mFileDescriptor;
	FileInputStream mInputStream;
	FileOutputStream mOutputStream;

	/**
	 * The message that indicates that we're sending a key to the lock.
	 */
	private static final int MESSAGE_KEY = 1;
	/**
	 * The message that indicates that we want to change the status of the lock.
	 */
	private static final int MESSAGE_LOCK = 2;
	/**
	 * The message that indicates that we want to change the lights attached to
	 * the lock (if any)
	 */
	private static final int MESSAGE_LIGHT = 3;

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

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
	}
}
