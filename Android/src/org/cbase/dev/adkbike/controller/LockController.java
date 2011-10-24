package org.cbase.dev.adkbike.controller;

import org.cbase.dev.adkbike.R;
import org.cbase.dev.adkbike.app.SocialBikeActivity;

import android.content.res.Resources;
import android.graphics.drawable.Drawable;
import android.text.SpannableStringBuilder;
import android.text.style.RelativeSizeSpan;
import android.text.style.SubscriptSpan;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.CompoundButton.OnCheckedChangeListener;
import android.widget.TextView;
import android.widget.ToggleButton;

public class LockController implements OnCheckedChangeListener {
	private final byte mCommandTarget;
	private SocialBikeActivity mActivity;
	private TextView mLabel;
	private ToggleButton mButton;
	private Drawable mOffBackground;
	private Drawable mOnBackground;

	public LockController(SocialBikeActivity activity, Resources res) {
		mActivity = activity;
		mCommandTarget = (byte) 11;
		mOffBackground = res
				.getDrawable(R.drawable.toggle_button_off_holo_dark);
		mOnBackground = res.getDrawable(R.drawable.toggle_button_on_holo_dark);
	}

	public void attachToView(ViewGroup targetView) {
		mLabel = (TextView) targetView.getChildAt(0);
		SpannableStringBuilder ssb = new SpannableStringBuilder(
				mActivity.getString(R.string.lock));
		ssb.setSpan(new SubscriptSpan(), 5, 6, 0);
		ssb.setSpan(new RelativeSizeSpan(0.7f), 5, 6, 0);
		mLabel.setText(ssb);
		mButton = (ToggleButton) targetView.getChildAt(1);
		mButton.setOnCheckedChangeListener(this);
	}

	public void onCheckedChanged(CompoundButton arg0, boolean isChecked) {
		if (isChecked) {
			mButton.setBackgroundDrawable(mOnBackground);
		} else {
			mButton.setBackgroundDrawable(mOffBackground);
		}
		if (mActivity != null) {
			mActivity.sendCommand(SocialBikeActivity.COMMAND_LOCK,
					mCommandTarget, isChecked ? 1 : 0);
		}
	}

}
