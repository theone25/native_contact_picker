// Copyright 2017 Michael Goderbauer. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "ContactPickerPlugin.h"
@import AddressBookUI;
@import ContactsUI;
@interface ContactPickerPlugin ()<ABPeoplePickerNavigationControllerDelegate,CNContactPickerDelegate>
@end

@implementation ContactPickerPlugin {
  FlutterResult _result;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"native_contact_picker"
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
      
      if (@available(iOS 9.0, *)) {
          CNContactPickerViewController *contactPicker = [[CNContactPickerViewController alloc] init];
          contactPicker.delegate = self;
          contactPicker.displayedPropertyKeys = @[ CNContactPhoneNumbersKey ];
          
          [viewController presentViewController:contactPicker animated:YES completion:nil];
      } else {
          // Fallback on earlier versions
          ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
          picker.peoplePickerDelegate = self;
          picker.displayedProperties = [NSArray arrayWithObjects:
                                        [NSNumber numberWithInt:kABPersonPhoneProperty],
                                        nil];
          [viewController presentViewController:picker animated:YES completion:nil];
      }

  } else if ([@"openSettings" isEqualToString:call.method]) {
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
       //   [[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
          result(@YES);
   } else {
    result(FlutterMethodNotImplemented);
  }
}

// for IOS 9 +
- (void)contactPicker:(CNContactPickerViewController *)picker
didSelectContactProperty:(CNContactProperty *)contactProperty  API_AVAILABLE(ios(9.0)){
    NSString *fullName = [CNContactFormatter stringFromContact:contactProperty.contact
                                                         style:CNContactFormatterStyleFullName];
    
    if ([contactProperty.value isKindOfClass:[NSString class]]) {
        //phoneNumber = contactProperty.value;
        printf("luồng pick những thứ khác như email -> k handle");
    } else {
        NSString *phoneNumber;
        phoneNumber = [contactProperty.value stringValue];
        _result([NSDictionary
                 dictionaryWithObjectsAndKeys:fullName, @"fullName", phoneNumber, @"phoneNumber", nil]);
        _result = nil;
    }
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker  API_AVAILABLE(ios(9.0)){
    _result(nil);
    _result = nil;
}


// for IOS 8
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
