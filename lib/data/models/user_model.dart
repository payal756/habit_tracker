import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final int? age;

  @HiveField(4)
  final String? profession;

  @HiveField(5)
  final List<String> goals;

  @HiveField(6)
  final int coins;

  @HiveField(7)
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.profession,
    required this.goals,
    this.coins = 0,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      profession: json['profession']?.toString(),
      goals: json['goals'] != null ? List<String>.from(json['goals']) : [],
      coins: json['coins'] != null
          ? int.tryParse(json['coins'].toString()) ?? 0
          : 0,
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'profession': profession,
      'goals': goals,
      'coins': coins,
    };
  }
}
