package org.cbase.dev.adkbike.controller;

import org.cbase.dev.adkbike.app.SocialBikeActivity;
import org.cbase.dev.adkbike.widget.Slider;

import android.text.SpannableStringBuilder;
import android.text.style.RelativeSizeSpan;
import android.text.style.SubscriptSpan;
import android.view.ViewGroup;
import android.widget.TextView;

public class ServoController implements Slider.SliderPositionListener {
	private final int mServoNumber;
	private final byte mCommandTarget;
	private TextView mLabel;
	private Slider mSlider;
	private SocialBikeActivity mActivity;

	public ServoController(SocialBikeActivity activity, int servoNumber) {
		mActivity = activity;
		mServoNumber = servoNumber;
		mCommandTarget = (byte) (servoNumber - 1 + 0x10);
	}

	public void attachToView(ViewGroup targetView) {
		mLabel = (TextView) targetView.getChildAt(0);
		SpannableStringBuilder ssb = new SpannableStringBuilder("Servo");
		ssb.append(String.valueOf(mServoNumber));
		ssb.setSpan(new SubscriptSpan(), 5, 6, 0);
		ssb.setSpan(new RelativeSizeSpan(0.7f), 5, 6, 0);
		mLabel.setText(ssb);
		mSlider = (Slider) targetView.getChildAt(1);
		mSlider.setPositionListener(this);
	}

	public void onPositionChange(double value) {
		byte v = (byte) (value * 255);
		mActivity.sendCommand(SocialBikeActivity.COMMAND_LOCK, mCommandTarget,
				v);
	}

}
