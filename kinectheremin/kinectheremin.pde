/**
 * Inspiration and examples drawn from:
 *
 *  - "Making Things See", by Greg Borenstein
 *  - "SimpleOpenNI User3d test", by Max Rheiner
 *  - "Sonifying Processing" by Evan X. Merz
 */

import SimpleOpenNI.*;
import beads.*;

AudioContext audioContext;
SimpleOpenNI kinect;
WavePlayer sineTone[];
Glide sineFrequency[];
Gain sineGain[];
Gain masterGain;
float baseFrequency;
int sineCount = 10; // how many sine waves will be present in our additive tone?

void setup()
{
    setupAudio();
    setupKinect();
    size(kinect.depthWidth(), kinect.depthHeight());
}

void draw()
{
    background(0);
    kinect.update();
    image(kinect.depthImage(), 0, 0);

    if(kinect.isTrackingSkeleton(1)){

        PVector leftHand = translateJoint(SimpleOpenNI.SKEL_LEFT_HAND);
        PVector rightHand = translateJoint(SimpleOpenNI.SKEL_RIGHT_HAND);

        float volume = map(rightHand.z, 900, 2500, 1, 0);
        masterGain.setGain(volume);

        // update the fundamental frequency based on hand position
        baseFrequency = 20.0f + leftHand.x; // add 20 to the frequency because below 20Hz is inaudible to humans

        // update the frequency of each sine tone
        for( int i = 0; i < sineCount; i++)
            {
                sineFrequency[i].setValue(baseFrequency * ((float)(i+1) * (leftHand.y/height)));
            }

        //draw a red circle where the left hand is
        fill(255,0,0);
        ellipse(leftHand.x, leftHand.y, 25, 25);

        //draw a blue circle where the right hand is
        fill(0, 0, 255);
        ellipse(rightHand.x, rightHand.y, 25, 25);
    }

}

PVector translateJoint(int jointType)
{
    PVector jointPos = new PVector();
    kinect.getJointPositionSkeleton(1, jointType, jointPos);

    PVector projectedJointPos = new PVector();
    kinect.convertRealWorldToProjective(jointPos, projectedJointPos);

    return projectedJointPos;
}

void setupAudio()
{
    audioContext = new AudioContext();
    masterGain = new Gain(audioContext, 1, 0.5);
    audioContext.out.addInput(masterGain);

    sineFrequency = new Glide[sineCount];
    sineTone = new WavePlayer[sineCount];
    sineGain = new Gain[sineCount];

    float currentGain = 1.0f;
    for( int i = 0; i < sineCount; i++)
        {
            sineFrequency[i] = new Glide(audioContext, baseFrequency * i, 30); // create the glide that will control this WavePlayer's frequency
            sineTone[i] = new WavePlayer(audioContext, sineFrequency[i], Buffer.SINE); // create the WavePlayer

            sineGain[i] = new Gain(audioContext, 1, currentGain); // create the gain object
            sineGain[i].addInput(sineTone[i]); // then connect the waveplayer to the gain

            // finally, connect the gain to the master gain
            masterGain.addInput(sineGain[i]);

            currentGain -= (1.0 / (float)sineCount); // lower the gain for the next tone in the additive complex
        }

}

void setupKinect()
{
    kinect = new SimpleOpenNI(this);
    kinect.enableDepth();
    kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);
}


// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(int userId)
{
    println("onNewUser - userId: " + userId);
    println("  start pose detection");
    kinect.startPoseDetection("Psi",userId);
}

void onLostUser(int userId)
{
    audioContext.stop();
    println("onLostUser - userId: " + userId);
}

void onStartCalibration(int userId)
{
    println("onStartCalibration - userId: " + userId);
}

void onEndCalibration(int userId, boolean successfull)
{
    println("onEndCalibration - userId: " + userId + ", successfull: " + successfull);

    if (successfull)
        {
            println("  User calibrated !!!");
            kinect.startTrackingSkeleton(userId);
            audioContext.start();
        }
    else
        {
            println("  Failed to calibrate user !!!");
            println("  Start pose detection");
            kinect.startPoseDetection("Psi",userId);
        }
}

void onStartPose(String pose,int userId)
{
    println("onStartdPose - userId: " + userId + ", pose: " + pose);
    println(" stop pose detection");

    kinect.stopPoseDetection(userId);
    kinect.requestCalibrationSkeleton(userId, true);

}

void onEndPose(String pose,int userId)
{
    println("onEndPose - userId: " + userId + ", pose: " + pose);
}
