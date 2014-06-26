#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"
#import "AVSoundPlayer.h"

class ofApp : public ofxiOSApp{
	
    public:
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
        ofSoundPlayer frosk;
        ofSoundPlayer hest;
        ofSoundPlayer kattepus;
    
        ofSoundPlayer flodhest;
        /*ofSoundPlayer apekatt;
        ofSoundPlayer mus;
        ofSoundPlayer sebra;*/

    
    
    
        ofTrueTypeFont font;
};


