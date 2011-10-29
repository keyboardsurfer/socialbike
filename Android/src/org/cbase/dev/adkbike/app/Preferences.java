package org.cbase.dev.adkbike.app;

import org.cbase.dev.adkbike.R;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.preference.EditTextPreference;
import android.preference.PreferenceActivity;
import android.widget.Toast;

public class Preferences extends PreferenceActivity {

	private EditTextPreference keyPreference;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		addPreferencesFromResource(R.xml.preferences);
		keyPreference = (EditTextPreference) findPreference(getString(R.string.preference_key));

		Intent intent = getIntent();
		final String scheme = intent.getScheme();
		if (scheme.equals("http") || scheme.equals("bikekey")) {
			Uri data = intent.getData();
			if (data != null) {
				String segment = data.getLastPathSegment();
				if (segment != null) {
					keyPreference.getEditor()
							.putString(keyPreference.getKey(), segment)
							.commit();
					Toast.makeText(this,
							getString(R.string.received_key_x, segment),
							Toast.LENGTH_SHORT).show();
					finish();
				}
			}
			Toast.makeText(this, getString(R.string.could_not_retrieve_key),
					Toast.LENGTH_SHORT).show();
			finish();

		}
	}
}
