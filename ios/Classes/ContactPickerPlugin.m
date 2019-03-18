// Copyright 2017 Michael Goderbauer. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ContactPickerPlugin.h"
@import AddressBookUI;
@interface ContactPickerPlugin ()<ABPeoplePickerNavigationControllerDelegate>
@end

@implementation ContactPickerPlugin {
  FlutterResult _result;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"contact_picker"
                                  binaryMessenger:[registrar messenger]];
  ContactPickerPlugin *instance = [[ContactPickerPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}
UIViewController *viewController ;
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"selectContact" isEqualToString:call.method]) {
    if (_result) {
      _result([FlutterError errorWithCode:@"multiple_requests"
                                  message:@"Cancelled by a second request."
                                  details:nil]);
      _result = nil;
    }
    _result = result;

    viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
      ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
      picker.peoplePickerDelegate = self;
      picker.displayedProperties = [NSArray arrayWithObjects:
                                              [NSNumber numberWithInt:kABPersonPhoneProperty],
                                              nil];
      [viewController presentViewController:picker animated:YES completion:nil];

  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    if (property == kABPersonPhoneProperty) {
        
        ABMultiValueRef phones = ABRecordCopyValue(person, property);
        CFIndex index = ABMultiValueGetIndexForIdentifier(phones, identifier);
        NSString *phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, index));
        
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
        
        NSString *fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];

        _result([NSDictionary
                 dictionaryWithObjectsAndKeys:fullName, @"fullName", phoneNumber, @"phoneNumber", nil]);
        
       CFRelease(phones);
    }    
    _result = nil;
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    _result(nil);
    _result = nil;
}


@end
