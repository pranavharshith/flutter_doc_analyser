// import 'package:flutter/material.dart';

// class AuthButton extends StatelessWidget {
//   final String text;
//   final VoidCallback onPressed;

//   const AuthButton({required this.text, required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       child: Text(text, style: TextStyle(fontSize: 16)),
//       style: ElevatedButton.styleFrom(
//         padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//         backgroundColor: Colors.deepPurple,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AuthButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16)),
    );
  }
}
