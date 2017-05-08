//
//  OpenCVWrapper.m
//  Focals1
//
//  Created by Caspar Wylie on 17/09/2016.
//  Copyright © 2016 Caspar Wylie. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "opencv2/opencv.hpp"
#import "opencv2/highgui/ios.h"
#import "opencv2/imgproc/imgproc.hpp"
#import "opencv2/core/core.hpp"
#import <vector>

/*
 
 OPENCV ObjC / C++ COMPONENT
 
 */

using namespace std;

@implementation OpenCVWrapper

int buildingFoundInLine(cv::Mat frame,cv::Mat testFrame, cv::Point point1, cv::Point point2,bool forBuildingTap,bool forTapLimit){
    
    bool testing = true;
    int buildingFoundAt = -1;
    vector<int>  buildingColorBounds = {231,236};
    
    int focalBehindBuilding = -1;
    int buildingDectectThicknessOffset = 7;
    if(forBuildingTap == true){
        buildingDectectThicknessOffset = 2;
        cv::Point pointTemp1 = point1;
        point1 = point2;
        point2 = pointTemp1;
    }//even blue
    
    int backFromBuilding = 0;
    cv::LineIterator lineIter(frame, point1, point2);
    int buildingProb = 0;
    for(int i = 0; i < lineIter.count; i++, lineIter++){
        int colorVal = int(frame.at<uchar>(lineIter.pos()));
        if(colorVal > buildingColorBounds[0] && colorVal < buildingColorBounds[1]){
            buildingProb++;
            if(buildingDectectThicknessOffset <= buildingProb){
                buildingFoundAt = i;
                if(forTapLimit == true || forBuildingTap == true){
                   break;
                }
            }
            
            if(testing == true){
                circle(testFrame, lineIter.pos(), 1, cv::Scalar(0,255,0));
            }
           
            //visualisation of output
           
        }else{
            if(testing == true){
                if(buildingProb > buildingDectectThicknessOffset){
                    if(backFromBuilding > 5){
                        circle(testFrame, lineIter.pos(), 1, cv::Scalar(255,0,0));
                    }else{
                         circle(testFrame, lineIter.pos(), 1, cv::Scalar(0,0,255));
                    }
                }else{
                    circle(testFrame, lineIter.pos(), 1, cv::Scalar(0,0,255));
                }
            }
            if(buildingProb > buildingDectectThicknessOffset){
                backFromBuilding ++;
                if(backFromBuilding > 5){
                    focalBehindBuilding = 1;
                    break;
                }
            }
           
        }
    }
    
    if(forTapLimit == true || forBuildingTap == true){
        return buildingFoundAt;
    }else{
        return focalBehindBuilding;
    }
}

+(NSString*) buildingDetect: (double[][2])pxVals image:(UIImage*)UIMap currPoint:(double[2])currPointPX pxLength:(int) pxLength forTapLimit:(bool)forTapLimit forBuildingTap:(bool)forBuildingTap {

    //setup matrix
    cv::Mat orgFrame, taskFrame;
    UIImageToMat(UIMap, orgFrame);
    
    int frameHeight = orgFrame.rows;
    int frameWidth = orgFrame.cols;

    cv::Point currPoint = cv::Point(currPointPX[0]  * frameWidth, currPointPX[1] * frameHeight);
    
    cv::cvtColor(orgFrame, taskFrame, CV_BGR2GRAY);
    
    int count = 0;
    string toHide = "";
    
    int buildingAt = -1;
    
    while(count<pxLength){
        
        int colsX = pxVals[count][0] * frameWidth;
        int rowsY = pxVals[count][1] * frameHeight;
        cv::Point pointXY = cv::Point(colsX,rowsY);
        
        buildingAt = buildingFoundInLine(taskFrame, orgFrame,currPoint, pointXY, forBuildingTap, forTapLimit);
        if(buildingAt > -1 && forBuildingTap == false and forTapLimit == false){
            toHide += to_string(count) + ",";
        }
        count++;
    }
    
    //convert to UIIMAGE for view (for testing)

    UIImage* new1IMG = MatToUIImage(orgFrame);
    
    if(forTapLimit == false && forBuildingTap == false){
        NSString* toHideReturn = [NSString stringWithUTF8String:toHide.c_str()];
        return toHideReturn;
    }else{
        string buildingAtStr = to_string(buildingAt);
        NSString* buildingAtReturn = [NSString stringWithUTF8String:buildingAtStr.c_str()];
        return buildingAtReturn;
    }
}


@end
