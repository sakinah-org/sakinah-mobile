import '../handlers/translation_handler.dart';

mixin Validations {
  String isValidEmail(String email) {
    if (email.isEmpty) {
      return "الرجاء ادخال بريدك الإلكتروني";
    } else if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      return "البريد الإلكتروني المدخل غير صحيح";
    }
    return "";
  }

  String isValidPassword(String password) {
    if (password.isEmpty) {
      return "الرجاء ادخال كلمة المرور";
    } else if (password.length < 8) {
      return "كلمة المرور يجب ان تكون اكثر من 8 احرف";
    }
    return "";
  }

  String isValidPhone(String phone) {
    if (phone.isEmpty) {
      return translator.word("phone_validation_message");
    } else if (phone.length > 13) {
      return translator.word("phone_validation_format_message");
    }
    return "";
  }

  String isValidConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return "الرجاء ادخال كلمة المرور التأكيدية";
    } else if (confirmPassword != password) {
      return "كلمة المرور غير متطابقة";
    }
    return "";
  }

  String isValidCode(String code) {
    if (code.isEmpty) {
      return translator.word("otp_empty_validation_message");
    } else if (code.length < 6) {
      return translator.word("otp_length_validation_message");
    }
    return "";
  }

  String isValidName(String name) {
    if (name.isEmpty) {
      return translator.word("enter_full_name");
    } else if (name.length < 3) {
      return translator.word("full_name_length_validation");
    }
    return "";
  }

  String isValidFirstName(String name) {
    if (name.isEmpty) {
      return "الرجاء ادخال الاسم الاول";
    } else if (name.length < 3) {
      return "اسم لا يقل عن 3 حروف";
    }
    return "";
  }

  String isValidLastName(String name) {
    if (name.isEmpty) {
      return "الرجاء ادخال الاسم اللآخر";
    } else if (name.length < 3) {
      return "اسم لا يقل عن 3 حروف";
    }
    return "";
  }

  String isValidCivilNumber(String civilNumber) {
    if (civilNumber.isEmpty) {
      return "الرجاء ادخال رقم الهوية/الإقامة";
    } else if (civilNumber.length != 10) {
      return "يجب ان يتكون رقم الهوية/الإقامة من ١٠ ارقام فقط";
    }
    return "";
  }
}
