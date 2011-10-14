package org.cbase.dev.adkbike;

import android.content.Context;
import android.util.AttributeSet;

public class VerticalSlider extends Slider {
	public VerticalSlider(Context context) {
		super(context);
		initSliderView(context, true);
	}

	public VerticalSlider(Context context, AttributeSet attrs) {
		super(context, attrs);
		initSliderView(context, true);
	}

}
