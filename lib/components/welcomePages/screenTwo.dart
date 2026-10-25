import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

class _ScreenTwoState extends State<ScreenTwo> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(30),
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          "Social Media",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xffcbdfff),
                            borderRadius: BorderRadius.circular(100),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                              vertical: 2.0,
                            ),

                            child: Text(
                              "Every day",
                              style: TextStyle(
                                fontSize: 19,
                                color: Color(0xff203378),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" height="10px" viewBox="0 -960 960 960" width="40px" fill="#4063e4"><path d="M480-120q-150 0-255-105T120-480q0-150 105-255t255-105q10 0 20.5.67 10.5.66 24.17 2-37.67 31-59.17 77.83T444-660q0 90 63 153t153 63q53 0 99.67-20.5 46.66-20.5 77.66-56.17 1.34 12.34 2 21.84.67 9.5.67 18.83 0 150-105 255T480-120Zm0-66.67q102 0 179.33-61.16Q736.67-309 760.67-395.67q-23.34 9-49.11 13.67-25.78 4.67-51.56 4.67-117.46 0-200.06-82.61-82.61-82.6-82.61-200.06 0-22.67 4.34-47.67 4.33-25 14.66-55-91.33 28.67-150.5 107-59.16 78.34-59.16 175.67 0 122 85.66 207.67Q358-186.67 480-186.67Zm-6-288Z"/></svg>''',
                            height: 30,
                            width: 30,
                          ),

                          SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" height="40px" viewBox="0 -960 960 960" width="40px" fill="#58d7fa"><path d="M446.67-806.67V-920h66.66v113.33h-66.66Zm0 766.67v-113.33h66.66V-40h-66.66Zm360-406.67v-66.66H920v66.66H806.67Zm-766.67 0v-66.66h113.33v66.66H40Zm704-250.66-47.33-47.34 67.33-68 48 48-68 67.34Zm-548 550-48-48 68-67.34 47.33 47.34-67.33 68Zm568 0-67.33-68L744-262.67l68 67.34-48 48Zm-548-550-68-67.34 48-48 67.33 68L216-697.33ZM317-317q-67-67-67-163t67-163q67-67 163-67t163 67q67 67 67 163t-67 163q-67 67-163 67t-163-67Zm278.83-47.17q47.5-47.5 47.5-115.83t-47.5-115.83q-47.5-47.5-115.83-47.5t-115.83 47.5q-47.5 47.5-47.5 115.83t47.5 115.83q47.5 47.5 115.83 47.5t115.83-47.5ZM480-480Z"/></svg>''',
                            height: 30,
                            width: 30,
                          ),
                        ],
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "10:00",
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors.grey,
                            thickness: 2,
                            indent: 20,
                            endIndent: 20,
                          ),
                        ),

                        Text(
                          "08:00",
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PM • Blocked",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),

                        Text(
                          "AM • Unlocked",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
