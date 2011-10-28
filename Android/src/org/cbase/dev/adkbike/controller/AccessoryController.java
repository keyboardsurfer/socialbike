package org.cbase.dev.adkbike.controller;

import org.cbase.dev.adkbike.app.SocialBikeActivity;

import android.content.res.Resources;
import android.view.View;

public abstract class AccessoryController {

	protected SocialBikeActivity mHostActivity;

	public AccessoryController(SocialBikeActivity activity) {
		mHostActivity = activity;
	}

	protected View findViewById(int id) {
		return mHostActivity.findViewById(id);
	}

	protected Resources getResources() {
		return mHostActivity.getResources();
	}

	void accessoryAttached() {
		onAccesssoryAttached();
	}

	abstract protected void onAccesssoryAttached();

}