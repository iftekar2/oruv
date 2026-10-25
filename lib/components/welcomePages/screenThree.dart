import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ScreenThree extends StatefulWidget {
  const ScreenThree({super.key});

  @override
  State<ScreenThree> createState() => _ScreenThreeState();
}

class _ScreenThreeState extends State<ScreenThree> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     border: Border.all(color: Colors.grey),
                    //     borderRadius: BorderRadius.circular(30),
                    //   ),

                    //   child: Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 20.0,
                    //       vertical: 16.0,
                    //     ),

                    //     child: Column(
                    //       children: [
                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text(
                    //               "Social Media",
                    //               style: TextStyle(
                    //                 fontSize: 20,
                    //                 fontWeight: FontWeight.w600,
                    //               ),
                    //             ),

                    //             Container(
                    //               decoration: BoxDecoration(
                    //                 color: const Color(0xffcbdfff),
                    //                 borderRadius: BorderRadius.circular(100),
                    //               ),

                    //               child: const Padding(
                    //                 padding: EdgeInsets.symmetric(
                    //                   horizontal: 15.0,
                    //                   vertical: 2.0,
                    //                 ),

                    //                 child: Text(
                    //                   "Every day",
                    //                   style: TextStyle(
                    //                     fontSize: 19,
                    //                     color: Color(0xff203378),
                    //                     fontWeight: FontWeight.w500,
                    //                   ),
                    //                 ),
                    //               ),
                    //             ),
                    //           ],
                    //         ),

                    //         Padding(
                    //           padding: const EdgeInsets.symmetric(
                    //             vertical: 18.0,
                    //           ),

                    //           child: Row(
                    //             mainAxisAlignment:
                    //                 MainAxisAlignment.spaceBetween,
                    //             children: [
                    //               SvgPicture.string(
                    //                 '''<svg xmlns="http://www.w3.org/2000/svg" height="10px" viewBox="0 -960 960 960" width="40px" fill="#4063e4"><path d="M480-120q-150 0-255-105T120-480q0-150 105-255t255-105q10 0 20.5.67 10.5.66 24.17 2-37.67 31-59.17 77.83T444-660q0 90 63 153t153 63q53 0 99.67-20.5 46.66-20.5 77.66-56.17 1.34 12.34 2 21.84.67 9.5.67 18.83 0 150-105 255T480-120Zm0-66.67q102 0 179.33-61.16Q736.67-309 760.67-395.67q-23.34 9-49.11 13.67-25.78 4.67-51.56 4.67-117.46 0-200.06-82.61-82.61-82.6-82.61-200.06 0-22.67 4.34-47.67 4.33-25 14.66-55-91.33 28.67-150.5 107-59.16 78.34-59.16 175.67 0 122 85.66 207.67Q358-186.67 480-186.67Zm-6-288Z"/></svg>''',
                    //                 height: 30,
                    //                 width: 30,
                    //               ),

                    //               SvgPicture.string(
                    //                 '''<svg xmlns="http://www.w3.org/2000/svg" height="40px" viewBox="0 -960 960 960" width="40px" fill="#58d7fa"><path d="M446.67-806.67V-920h66.66v113.33h-66.66Zm0 766.67v-113.33h66.66V-40h-66.66Zm360-406.67v-66.66H920v66.66H806.67Zm-766.67 0v-66.66h113.33v66.66H40Zm704-250.66-47.33-47.34 67.33-68 48 48-68 67.34Zm-548 550-48-48 68-67.34 47.33 47.34-67.33 68Zm568 0-67.33-68L744-262.67l68 67.34-48 48Zm-548-550-68-67.34 48-48 67.33 68L216-697.33ZM317-317q-67-67-67-163t67-163q67-67 163-67t163 67q67 67 67 163t-67 163q-67 67-163 67t-163-67Zm278.83-47.17q47.5-47.5 47.5-115.83t-47.5-115.83q-47.5-47.5-115.83-47.5t-115.83 47.5q-47.5 47.5-47.5 115.83t47.5 115.83q47.5 47.5 115.83 47.5t115.83-47.5ZM480-480Z"/></svg>''',
                    //                 height: 30,
                    //                 width: 30,
                    //               ),
                    //             ],
                    //           ),
                    //         ),

                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text(
                    //               "10:00",
                    //               style: TextStyle(
                    //                 fontSize: 40,
                    //                 color: Colors.black,
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),

                    //             Expanded(
                    //               child: Divider(
                    //                 color: Colors.grey,
                    //                 thickness: 2,
                    //                 indent: 20,
                    //                 endIndent: 20,
                    //               ),
                    //             ),

                    //             Text(
                    //               "08:00",
                    //               style: TextStyle(
                    //                 fontSize: 40,
                    //                 color: Colors.black,
                    //                 fontWeight: FontWeight.w500,
                    //               ),
                    //             ),
                    //           ],
                    //         ),

                    //         Row(
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           children: [
                    //             Text(
                    //               "PM • Blocked",
                    //               style: TextStyle(
                    //                 fontSize: 18,
                    //                 color: Colors.grey[700],
                    //               ),
                    //             ),

                    //             Text(
                    //               "AM • Unlocked",
                    //               style: TextStyle(
                    //                 fontSize: 18,
                    //                 color: Colors.grey[700],
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
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

                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: const Color(0xffcbdfff),
                                ),

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  child: SvgPicture.string(
                                    '''<svg xmlns="http://www.w3.org/2000/svg" height="40px" viewBox="0 -960 960 960" width="40px" fill="#4063e4"><path d="M146.67-120q-27.5 0-47.09-19.58Q80-159.17 80-186.67v-466.66q0-27.5 19.58-47.09Q119.17-720 146.67-720H320v-93.33q0-27.5 19.58-47.09Q359.17-880 386.67-880h186.66q27.5 0 47.09 19.58Q640-840.83 640-813.33V-720h173.33q27.5 0 47.09 19.58Q880-680.83 880-653.33v466.66q0 27.5-19.58 47.09Q840.83-120 813.33-120H146.67Zm240-600h186.66v-93.33H386.67V-720Zm-142 66.67h-98v466.66h98v-466.66Zm404.66 466.66v-466.66h-338v466.66h338ZM716-653.33v466.66h97.33v-466.66H716Zm-236 230Z"/></svg>''',
                                    height: 32,
                                    width: 32,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "At work",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    Text(
                                      "Deep work, fewer pings",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
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

                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: const Color(0xffcbdfff),
                                ),

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  child: SvgPicture.string(
                                    '''<svg xmlns="http://www.w3.org/2000/svg" height="40px" viewBox="0 -960 960 960" width="40px" fill="#4063e4"><path d="M479.33-120 192.67-276.67v-240L40-600l439.33-240L920-600v318h-66.67v-280L766-516.67v240L479.33-120Zm0-316 301.34-164-301.34-162-300 162 300 164Zm0 240.33 220-120.66v-162.34L479.33-360l-220-120v163.67l220 120.66ZM480-436Zm-.67 79.33Zm0 0Z"/></svg>''',
                                    height: 32,
                                    width: 32,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "At school",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    Text(
                                      "Stay present in class",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Container(
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

                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: const Color(0xffcbdfff),
                                ),

                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                  child: SvgPicture.string(
                                    '''<svg xmlns="http://www.w3.org/2000/svg" height="40px" viewBox="0 -960 960 960" width="40px" fill="#4063e4"><path d="M80-120v-720h393.33v163.33H880V-120H80Zm66.67-66.67h96.66v-96.66h-96.66v96.66Zm0-163.33h96.66v-96.67h-96.66V-350Zm0-163.33h96.66V-610h-96.66v96.67Zm0-163.34h96.66v-96.66h-96.66v96.66Zm163.33 490h96.67v-96.66H310v96.66ZM310-350h96.67v-96.67H310V-350Zm0-163.33h96.67V-610H310v96.67Zm0-163.34h96.67v-96.66H310v96.66Zm163.33 490h340V-610h-340v96.67h80v66.66h-80V-350h80v66.67h-80v96.66Zm176.67-260v-66.66h66.67v66.66H650Zm0 163.34V-350h66.67v66.67H650Z"/></svg>''',
                                    height: 32,
                                    width: 32,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "In College",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    Text(
                                      "Study sessions that stick",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Text(
              "Focus anywhere",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: const Color(0xff4063e4),
                fontFamily: GoogleFonts.sora().fontFamily,
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "Made for the moments that matter.",
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.sora().fontFamily,
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Create focus modes for work, school or college and get back hours of attention every week.",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 20,
                fontFamily: GoogleFonts.sora().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
