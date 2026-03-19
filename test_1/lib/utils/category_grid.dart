import 'package:flutter/material.dart';

class CategoryGrid extends StatefulWidget {
  String title = "";
  IconData icon = Icons.person;
  CategoryGrid({super.key, required this.title, required this.icon, required});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xffD8D7FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 40,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
        ));
  }
}
