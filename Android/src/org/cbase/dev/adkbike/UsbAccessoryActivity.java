package org.cbase.dev.adkbike;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

/**
 * User: biafra
 * Date: 10/6/11
 * Time: 4:41 PM
 */
public class UsbAccessoryActivity extends Activity {
  static final String TAG = "UsbAccessoryActivity";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    Intent intent = new Intent(this, ADKBikeActivity.class);

    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                    | Intent.FLAG_ACTIVITY_CLEAR_TOP);
    try {
      Log.e(TAG, "Starting ADKBikeActivity activity..:");

      startActivity(intent);

    } catch (ActivityNotFoundException e) {
      Log.e(TAG, "unable to start ADKBikeActivity activity", e);
    }
    finish();
  }
}