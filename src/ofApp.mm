#include "ofApp.h"


///< Remove soundwave vectors if alpha is 0 or less.
bool shouldRemove(Particles &p)
{
    if(p.alpha <= 0 )return true;
    else return false;
}


//--------------------------------------------------------------
void ofApp::setup()
{
    ///< Setup framerate, background color and show mouse
    ofSetFrameRate( 60 );
    ofBackground( 0, 0, 0 );
    //ofSetVerticalSync( true );

    
    touchobject.Setup();
    
    menu.setup();
    
    about.setup();
    

    touchPosX               = 0;
    touchPosY               = 0;
    triggerFileSamplePlay   = false;
    triggerRecSamplePlay    = false;
    //triggerPlay             = false;
    soundSpeed              = 1.0;
    fingerIsLifted          = false;
    touchIsDown             = false;
    addParticlesTimer       = 0;

    
    
    ///< M A X I M I L I A N
    sampleRate              = 44100;
    initialBufferSize       = 512;
    panning                 = 0.5;
    volume                  = 0.0;
    sample                  = 0.0;
    _filterLeftRight        = 0.0;
    

    ///< openFrameworks sound stream
    //ofSoundStreamSetup( 2, 1, this, sampleRate, initialBufferSize, 4 );
    soundStream.setup( this, 2, about._audioInputValue, sampleRate, initialBufferSize, 4 );
    
    
    
    // Setup FFT
    fftSize = BANDS;
    myFFT.setup( fftSize, 1024, 256 );
    //nAverages = 12;
    //myFFTOctAna.setup(sampleRate, fftSize/2, nAverages);


    ///// R E C O R D I N G /////
    // Order here is important to check if rec file has content. If no content, rec button will be shown.
    for ( int i = 0; i < NUM_OF_REC_MODES; i++ ) {
        recording[i].setup( i, about._audioInputValue );
        recSample[i].load( recording[i].myRecString );
        recording[i].isRecSampleZero( recSample[i].length );
    }

    
    
    // Load samples
    loadFileSamples();


    
   /* for (int i = 1; i < NUM_OF_HARDCODED_SOUNDS + 1; i++)
    {
        string fileNr = "Sound_Object_0" + ofToString( i ) + ".wav";
        fileSample[i].load( ofToDataPath( fileNr ) );
    }*/
    
    
    
    

    ofSetOrientation( OF_ORIENTATION_90_LEFT ); // Set this after recording.Setup() and menu.Setup() because of issue with ofGetWidth() vs ofGetScreenWidth().

    
    
    
    
}

//--------------------------------------------------------------
void ofApp::loadFileSamples() {
    
    // Are there any wav sound files in dir?
    bool filesExist = false;

    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString *documentsPath = [searchPaths objectAtIndex:0];
    NSString *extension = @"wav";
    NSFileManager *fileManager = [ NSFileManager defaultManager ];
    NSArray *contents = [ fileManager contentsOfDirectoryAtPath: documentsPath error: NULL ];
    NSEnumerator *e = [ contents objectEnumerator ];
    NSString *fileName;
    
    int fileCounter = 0; // Prevent from loading more than 7 sounds
    
    while ( ( fileName = [ e nextObject ] ) ) {
        if ( [ [ fileName pathExtension ] isEqualToString: extension ] ) {
            NSLog( @"FileName: %@", fileName );
            NSString *soundFilePath = [ documentsPath stringByAppendingPathComponent: fileName ];
            string myFileString = ofxNSStringToString( soundFilePath );
            fileCounter++;
            if ( fileCounter <= 7 ) {
                vectorOfStrings.push_back( myFileString ); // Fill my own vector with strings
            }

            filesExist = true;
        }
    }
    
    ofLog() << "fileCounter: " << fileCounter;
    
    

    ofLog() << "filesExist: " << filesExist;
    
    if ( filesExist ) {
        
        ofLog() << "vectorOfStrings.size(): " << vectorOfStrings.size();
        howManySamples = vectorOfStrings.size();
        
        // Load the user installed (from iTunes to Document dir) file samples
        // Load file sample strings into ofxMaxiSample fileSample.
        for ( int i = 0; i < vectorOfStrings.size(); i++ ) {
            fileSample[i].load( ofToDataPath( vectorOfStrings.at( i ) ) );
        }
        
        // Empty vector from memory
        for ( int i = 0; i < vectorOfStrings.size(); i++ ) {
            vectorOfStrings.erase( vectorOfStrings.begin() + i );
        }
            
    }
    else
    {
        howManySamples = NUM_OF_HARDCODED_SOUNDS;
        
        // Otherwise load the hard coded file samples
        for (int i = 0; i < NUM_OF_HARDCODED_SOUNDS; i++)
        {
            string fileNr = "Sound_Object_0" + ofToString( i ) + ".wav";
            fileSample[i].load( ofToDataPath( fileNr ) );
        }
    }
    

    


}

//--------------------------------------------------------------
void ofApp::update()
{
    
    ///< MAXIMILIAN
    float *val = myFFT.magnitudesDB;

    
    ///< Update spectrum analyze
    touchobject.Update( val );

    
    ///< Increase radius of particles, and decrease alpha

    for( int i = 0; i < particles.size(); i++ ) {
        particles[i].Update( soundSpeed, sample );
    }

    
    menu.update( );
    
    
    ///< Remove soundwave when alpha is 0
    ofRemove( particles, shouldRemove );
    
    
    ///< Add particles
    if ( !menu._isInMenu && recording[ menu._whatRecSample ].readyToPlay ) {// Do not add waves when pushing change-song-button.
        
        if ( touchobject.spectrumVolume > 1200 && volume > 0.0 ) {
            
            addParticlesTimer += ofGetLastFrameTime();
            if ( addParticlesTimer >= 0.01 ) {
                particles.push_back( Particles(touchPosX, touchPosY, touchobject.SpectrumVolume(), touchobject.StartRadius(), touchobject.ColorBrightness(), soundSpeed ) );
                addParticlesTimer = 0;
            }
        }
    }



    ///// R E C O R D I N G /////

    if ( menu._whatMode == kModeRec )
    //if ( menu.recModeOn[ menu.whatRecSample ] )
    {
        recording[ menu._whatRecSample ].Update( touchPosX, touchPosY, touchIsDown );
    }
    
    // Load rec sample after recording (loadFileIsDone flag to prevent rec sample from being played before it is loaded)
    if ( recording[ menu._whatRecSample ].saveFileIsDone )
    {
        recSample[ menu._whatRecSample ].load( recording[ menu._whatRecSample ].myRecString );
        recording[ menu._whatRecSample ].loadFileIsDone = true;
        recording[ menu._whatRecSample ].saveFileIsDone = false;
    }
    
    // Prevent rec sample from playing instantly after finger is lifted from rec button.
    if ( recording[ menu._whatRecSample ].loadFileIsDone && touchIsDown ) {
        recording[ menu._whatRecSample ].muteAudioWhileRecording = false;
    }
    
    // Set ready to play if not in rec mode
    /*if ( !menu.recModeOn[ menu.whatRecSample ] )
    {
        recording[ menu._whatRecSample ].readyToPlay = true;
    }*/

    
    
    // About Bit20
    if ( menu._aboutIsOpen ) {
        about.update();
        
        if ( about._closeAbout ) {
            menu._aboutIsOpen = false;;
            about._closeAbout = false;
        }
    }
    
    
}

//--------------------------------------------------------------
void ofApp::draw()
{
    
    // Draw menu-button
    menu.draw( );
    
    ///// R E C O R D I N G /////
    if ( !menu._isInMenu && !menu._aboutIsOpen ) {
        if ( menu._whatMode == kModeRec ) {
        //if ( menu.recModeOn[ menu.whatRecSample ] ) {
            recording[ menu._whatRecSample ].Draw();
        }
    }
    
    
    // About Bit20
    if ( menu._aboutIsOpen ) {
        about.draw();
    }
    
    ///< Draw touchobject
    if ( !menu._muteAudio ) {
        touchobject.Draw();
    }
    
    ///< Draw particles
    for( int i = 0; i < particles.size(); i++ )
    {
        particles[i].Draw();
    }


    
    /*ofSetColor( 255, 255, 255 );
    ofDrawBitmapString( "fps: "+ ofToString( ofGetFrameRate() ), 10, 20 );
    ofDrawBitmapString( "what sample: "+ ofToString( menu.whatSample ), 10, 40 ) ;
    ofDrawBitmapString( "what menu num: "+ ofToString( menu.whatMenuNum ), 10, 60 );
    ofDrawBitmapString( "what REC sample: "+ ofToString( menu.whatRecSample ), 10, 80 );*/
}

//--------------------------------------------------------------
void ofApp::exit(){

    ///// R E C O R D I N G /////
    for ( int i = 0; i < NUM_OF_REC_MODES; i++ ) {
        recording[ i ].Exit();
    }
    
    soundStream.close();
    
}

//--------------------------------------------------------------


///< ----------- M A X I M I L I A N -------------
void ofApp::audioOut(float * output, int bufferSize, int nChannels)
{
    
    if( initialBufferSize != bufferSize )
    {
        ofLog( OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize );
        return;
    }
    
	
	ofxMaxiMix channel1;
	//double sample;
	double stereomix[2];
    double myOutput;
    double myDelayOutput;
    //double myDistortionOutput;
    //double myFlangOutput;
    //double myChorusOutput;
    //double myNormalizedOutput;

	

    
    // Calculate audio vector by iterating over samples
    
    for ( int i = 0; i < bufferSize; i++ )
    {
        

        if ( menu._whatMode == kModeRec )
        {
            if ( recording[ menu._whatRecSample ].readyToPlay ) {
                if ( recording[ menu._whatRecSample ].loadFileIsDone ) {
                    if ( !recording[ menu._whatRecSample ].silenceWhenDeleting && !recording[ menu._whatRecSample ].muteAudioWhileRecording ) {
                        if ( triggerRecSamplePlay ) {
                            sample = recSample[ menu._whatRecSample ].playOnce( soundSpeed );
                        } else {
                            sample = 0.;
                        }
                    }
                }
            }
        }
        else if ( menu._whatMode == kModeFileSample )
        {
            if ( triggerFileSamplePlay ) {
                sample = fileSample[ menu._whatFileSample ].playOnce( soundSpeed );
            } else {
                sample = 0.;
            }
        }
        
        
        
        
        
        
        if ( about._isDelayActive ) {
            //myOutput = myDelay.dl( sample, _filterLeftRight, 0.8 );
       
            // Flanger: input, delay, feedback, speed, depth
            //myFlangOutput = myFlanger.flange( sample, 14000, 0.7, 0.5, 0.8 );
            
            //myDistortionOutput = myDistortion.fastAtanDist( sample, _effectLeftRight );
            
            // Delay line with feedback ( double input, int size, double feedback ) size = delay time

            
            // Chorus: input, delay, feedback, speed, depth
            //myChorusOutput = myChorus.chorus( sample, _filterLeftRight, 0.1, 0.5, 0.8 );
            
            //myOutput = myDelayOutput;
            //myOutput = myDistortion.atanDist( sample, 50 );
            
            myDelayOutput = myDelay.dl( sample, _filterLeftRight, 0.8 );
            myOutput = myDelayOutput;
        
            
        } else {
            myOutput = sample;
        }
     
        
            
        // Stereo panning
        channel1.stereo( myOutput, stereomix, panning );

        
        // Process FFT Spectrum
        if ( myFFT.process( myOutput ) )
        {
            myFFT.magsToDB();
            //myFFTOctAna.calculate( myFFT.magnitudes );
        }

        
        output[i*nChannels    ] = stereomix[0] * volume;
        output[i*nChannels + 1] = stereomix[1] * volume;
        
    }
    
    
    ///< Change sound speed
    if ( !menu._isInMenu )
    {
        
        if ( touchPosY > ofGetHeight() / 2 )
        {
            soundSpeed = ofMap( touchPosY, ofGetHeight() / 2, ofGetHeight(), 1.0, 0.1, true );
        }
        else if ( touchPosY < ofGetHeight() / 2 )
        {
            soundSpeed = ofMap( touchPosY, ofGetHeight() / 2, 0, 1.0, 1.5, true );
        }
    }
    
    
    ///< Change sound panning
    panning = ofMap( touchPosX, 0, ofGetWidth(), 0.0, 1.0, true );
    //panning = 0.5;
    
    if ( about._isDelayActive ) {
        _filterLeftRight = ofMap( touchPosX, 0, ofGetWidth(), 1400, 14000, true );
    }
    
    
    
    ///< Fade out volume when finger is lifted or menu is pressed
    if ( fingerIsLifted  )
    {
        if ( volume >= 0.0 )
        {
            volume = volume - 0.005;
        }
    } else if ( menu._isInMenu ) {
        if ( volume >= 0.0 )
        {
            volume = volume - 0.005;
        }
    }
    
    if ( menu._isInMenu ) {
        if ( volume >= 0.0 )
        {
            volume = volume - 0.05;
        }
    }
    
    
    ///< Stop playback when volume is 0 or less.
    if ( volume <= 0.0 )
    {
        triggerFileSamplePlay = false;
        triggerRecSamplePlay = false;
        fingerIsLifted = false;
    }
    
    
    if ( menu._muteAudio ) {
        volume = 0.0;
    }
}



/*void ofApp::audioReceived(float *input, int bufferSize, int nChannels) {

}*/


//--------------------------------------------------------------
void ofApp::touchDown( ofTouchEventArgs & touch )
{
    ///< Update position of particles when touch is pressed
    touchPosX = touch.x;
    touchPosY = touch.y;

    // Used to decrease volume when finger is lifted
    fingerIsLifted = false;
    
    // Audio input value button (bluetooth) AND delay on/off button
    if ( menu._aboutIsOpen ) {
        about.distanceToButton( touch.x, touch.y );
        about.distanceToCloseButton( touch.x, touch.y );
    }
    
    // Tiny button
    if ( !menu._isInMenu && !menu._aboutIsOpen ) {
        menu.distanceToTinyButton( touch.x, touch.y );
    }
    // Pictogram buttons
    if ( menu._isInMenu ) {
        menu.distanceToMenuButtons( touch.x, touch.y );
    }
    

    if ( !menu._isInMenu ) {
        // Check if delete button is pressed
        recording[ menu._whatRecSample ].distanceToDeleteButton( touch.x, touch.y );
        // Rec button
        recording[ menu._whatRecSample ].distanceToRecButton( touch.x, touch.y );
    }
    
    ///< Detect if finger is inside menu-button or del button
    if ( menu._whatMode == kModeRec && recording[ menu._whatRecSample ].delButtonIsPressed )
    {
        volume = 0.0;
    }
    
    if ( !menu._isInMenu && !menu._aboutIsOpen ) {
    
        // Set position of samples to 0 when finger is pressed
        fileSample[ menu._whatFileSample ].setPosition( 0. );
        recSample[ menu._whatRecSample ].setPosition( 0. );
        
        triggerFileSamplePlay = true;
        triggerRecSamplePlay = true;
        volume = 1.0;
        // Set position of touchobject when touch is moved
        touchobject.Position( touch.x, touch.y );
    }

    
    touchIsDown = true;
}

//--------------------------------------------------------------
void ofApp::touchMoved( ofTouchEventArgs & touch )
{
    ///< Set position of touchobject when touch is moved
    if ( !menu._isInMenu )
    {
        touchobject.Position( touch.x, touch.y );
    }
    
    ///< Update position of particles when touch moves
    touchPosX = touch.x;
    touchPosY = touch.y;
    

}

//--------------------------------------------------------------
void ofApp::touchUp( ofTouchEventArgs & touch )
{
    // Used to decrease volume when finger is lifted
    fingerIsLifted = true;
    
    recording[ menu._whatRecSample ].delButtonIsPressed = false;
    
    recording[ menu._whatRecSample ].silenceWhenDeleting = false;

    touchIsDown = false;
    

}




//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}
