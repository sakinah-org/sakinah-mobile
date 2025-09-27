
class User {
  String? token;
  String? userId;
  String? firstName;
  String? lastName;
  String? email;

  User({
    this.token,
    this.userId,
    this.firstName,
    this.lastName,
    this.email,

  });
  User.fromJson(Map<String, dynamic> json) {
    userId = json['_id'];
    firstName = json['firstname'];
    lastName = json['lastname'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.userId;
    data['firstname'] = this.firstName;
    data['lastname'] = this.lastName;
    data['email'] = this.email;
    return data;
  }
}

enum BanStatus { normal, banned }

enum Ranks {
  normal,
  unNormal,
}
