import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

getPickedImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);
  if (file != null) {
    return await file.readAsBytes();
  }else{
    Get.snackbar("Error", "No image was selected");
  }
}
