// Copyright 2017 Michael Goderbauer. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package vn.sendo.flutter.contactpicker;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;
import android.provider.Settings;

import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;

import static android.app.Activity.RESULT_OK;

public class ContactPickerPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, PluginRegistry.ActivityResultListener {

  private static int PICK_CONTACT = 2015;
  private static final String CHANNEL_NAME = "native_contact_picker";

  private Activity activity;
  private Result pendingResult;
  private MethodChannel channel;

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
    channel.setMethodCallHandler(this);
    binding.addActivityResultListener(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("selectContact")) {
      if (pendingResult != null) {
        pendingResult.error("multiple_requests", "Cancelled by a second request.", null);
        pendingResult = null;
      }
      pendingResult = result;

      Intent i = new Intent(Intent.ACTION_PICK, ContactsContract.CommonDataKinds.Phone.CONTENT_URI);
      activity.startActivityForResult(i, PICK_CONTACT);
    } else if (call.method.equals("openSettings")) {
      openSettings();
      pendingResult.success(true);
      pendingResult = null;
    }
    else {
      result.notImplemented();
    }
  }
  // private Registrar registrar;

  private void openSettings() {
    //Activity activity = registrar.activity();
    Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + activity.getPackageName()));
    intent.addCategory(Intent.CATEGORY_DEFAULT);
    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    activity.startActivity(intent);
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode != PICK_CONTACT) {
      return false;
    }
    if (resultCode != RESULT_OK) {
      pendingResult.success(null);
      pendingResult = null;
      return true;
    }
    Uri contactUri = data.getData();
    Cursor cursor = activity.getContentResolver().query(contactUri, null, null, null, null);
    cursor.moveToFirst();

    int phoneType = cursor.getInt(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE));
    String customLabel = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.LABEL));
    String label = (String) ContactsContract.CommonDataKinds.Email.getTypeLabel(activity.getResources(), phoneType, customLabel);
    String number = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
    String fullName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME));
    String avatar = cursor.getString(cursor.getColumnIndex(ContactsContract.Contacts.PHOTO_THUMBNAIL_URI));

//    HashMap<String, Object> phoneNumber = new HashMap<>();
//    phoneNumber.put("number", number);
//    phoneNumber.put("label", label);

    HashMap<String, Object> contact = new HashMap<>();
    contact.put("fullName", avatar);
    contact.put("phoneNumber", number);

    pendingResult.success(contact);
    pendingResult = null;
    return true;
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {

  }
}
