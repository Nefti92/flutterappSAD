import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isObscure;
  final TextInputType keyboardType;
  final Color textColor;
  final Color hintColor;
  final double fontSize;
  final Color backgroundColor;
  final double borderWidth;
  final Color borderColor;
  final double height;
  final double width;

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.hintColor = Colors.black,
    this.textColor = Colors.black,
    this.fontSize = 16.0,
    this.backgroundColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderColor = Colors.grey,
    this.height = 60.0,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor, // Colore di sfondo del campo
        borderRadius: BorderRadius.circular(8.0), // Bordo arrotondato
        border: Border.all(
          color: borderColor,   // Colore del bordo
          width: borderWidth,   // Larghezza del bordo
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintStyle: TextStyle(
            color: hintColor
          ),
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none, // Rimuove il bordo predefinito
          prefixIcon: Icon(prefixIcon),
          contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        ),
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}