#import "MyOpenGLView.h"
#import <Cocoa/Cocoa.h>
@interface ViewController : NSViewController
@property (weak) IBOutlet MyOpenGLView *openGLView;
@property (weak) IBOutlet NSTextField *zoomText;
@property (weak) IBOutlet NSTextField *posXText;
@property (weak) IBOutlet NSTextField *posYText;
@property (weak) IBOutlet NSTextField *posZText;
@property (weak) IBOutlet NSTextField *pitchText;
@property (weak) IBOutlet NSTextField *yavText;
@property (weak) IBOutlet NSButton *generateRandomButton;
@property (weak) IBOutlet NSButton *deleteSelectedButton;
@property (weak) IBOutlet NSButton *addPointButton;
@property (weak) IBOutlet NSColorWell *colorWell;
@property (weak) IBOutlet NSSegmentedControl *editModeSwitch;
@property (weak) IBOutlet NSMatrix *shadingSelector;
@property (weak) IBOutlet NSButton *wireframeCheck;
@property (weak) IBOutlet NSButton *showControlPointsCheck;
@property (weak) IBOutlet NSSlider *transparencySlider;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSSegmentedControl *mappingChooser;
@property (weak) IBOutlet NSTextField *transparencyText;

@end
