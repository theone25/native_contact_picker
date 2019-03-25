
# native_contact_picker
A flutter plugin to open native contact app and pink a contact with phone number
A new version of [contact_picker](https://pub.dartlang.org/packages/contact_picker) with IOS 8 supporting.

[![pub package](https://img.shields.io/pub/v/native_contact_picker.svg)](https://pub.dartlang.org/packages/native_contact_picker)

### Installation 

See installing tab 


### Example  


```yaml
import 'package:native_contact_picker/native_contact_picker.dart';

final NativeContactPicker _contactPicker = new NativeContactPicker();
Contact contact = await _contactPicker.selectContact();
```