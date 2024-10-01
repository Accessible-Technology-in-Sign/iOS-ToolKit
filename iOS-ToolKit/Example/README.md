### Sign Language Recognition Gesture Toolkit

# How the HomeViewController works

HomeViewController is a UIViewController

* To create a new UIButton:
    - create a button object
    - create a button configuration using UIButton and set its configuration to what is desired (i.e. plain)
    - set a title for the button configuration using ".title"
    - set an associated image to the button configuration using ".image"
    - to add padding on the image for the button configuration use ".imagePadding"
    - set the created button object's configuration to the created button configuration
    - return the button

* To create a new UILabel
    - create a UILabel and name it
    - set its text by using ".text"
    - set the associated text's alignment using the ".textAlignment"
    - return the UILabel

* To create a new UIStackView
    - create a new UIStackView passing in your created button and label
    - set the stackView's axis by using ".axis"
    - set the stackView's spacing by using ".spacing"
    - set the stackView's alignment by using ".alignment"
    - set the stackView's distribution by using ".distribution"
    - return the UIStackView

* Create a new cameraView by instantiating a SLRGTKCameraView

* Setting up the Camera View
    - check if the view did load
    - set the view background color by using ".backgroundColor"
    - Using the stackView you created set its auto resizing to false and add it as a Subview of view
    - using NSLayoutContraint activate the anchors on your stackView, adjusting the leadingAnchor, trailingAnchor, bottomAnchor, and centerXAnchor
    - set the cameraView you created to be hidden
    - add it as a Subview to your view and set its auto resizing to be false
     - using NSLayoutContraint activate the anchors on your stackView, adjusting the leadingAnchor, trailingAnchor, topAnchor, and bottomAnchor
     - set the cameraView to delegate to self
     - using your startButton add target cases
     - 1. for touchDown inside of the StartButton
        - use the cameraView set up the engine
        - fade in the cameraView with ".fadeIn()" and set self.cameraView to start()
        - using the stackView call fadeOut and set modifiesHiddenBehaviour to be false

     - 2. for touchUp inside of the StartButton
     - 3. for touchUp outside of the StartButton
        - for both 2 and 3
        - use the cameraView to detect and fadeOut
        - have the stackView fadeIn and set modifiesHiddenBehavior to be false
        - set the startButton.isEnabled to be false
        - set your UILabel text to be "processing" or something similar

* Checks for the Camera View
    - If the camera did setup correctly print out some message signifying so
    - If the camera did begin inferring the sign set the UILabel text to signify this
    - If the camera completed inferring the sign set the UILabel text to the infered sign if it is within the list of signs, and reset the DetectButton
    - If the camera throws an error set the self UILabel text to signify this and then set the self DetectButton to reset, print out the error description

* Reseting the Detection Button
    - create a buttonConfiguration and set it to the same configuration as the startButton
    - set the title of the new buttonConfiguration to prompt the user to attempt another detection
    - set the startButton configuration to be the new edited buttonConfiguration and set the startButton as enabled
     

# How the UIView+Fade works

* Using the fadeIn function
    - set alpha equal to zero
    - check if modifiesHidenBehaviour is true, if so isHidden is set to false
    - set the UIView animate with durations and animations and set self.alpha to 1
    - check for completion with a boolean value in the onCompletion function

* Using the fadeOut function
    -set UIView animate with duration and animations and set self.alpha to 0
    - check for completion with a boolean value in the onCompletion function and check if modifiesHiddenBehavior is true, if it is then set self to be hidden.