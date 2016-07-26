#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.

    [self.wireframeCheck
        setState:self.openGLView.SHOW_WIREFRAME ? NSOnState : NSOffState];
    [self.showControlPointsCheck
        setState:self.openGLView.SHOW_CONTROL_POINTS ? NSOnState : NSOffState];
    [self.shadingSelector selectCellAtRow:self.openGLView.shading column:0];
    [self.zoomText setFloatValue:self.openGLView.zoom];
    [self.posXText setFloatValue:self.openGLView.xpos];
    [self.posYText setFloatValue:self.openGLView.ypos];
    [self.posZText setFloatValue:self.openGLView.zpos];
    [self.pitchText setFloatValue:self.openGLView.xrot];
    [self.yavText setFloatValue:self.openGLView.yrot];
    self.colorWell.color = self.openGLView.color;
    [self.openGLView setViewController:self];

    self.generateRandomButton.enabled   = FALSE;
    self.addPointButton.enabled         = FALSE;
    self.deleteSelectedButton.enabled   = FALSE;
    self.wireframeCheck.enabled         = TRUE;
    self.shadingSelector.enabled        = TRUE;
    self.showControlPointsCheck.enabled = TRUE;
    [self.transparencyText
        setIntValue:self.openGLView.color.alphaComponent * 100];
    [self.transparencySlider
        setIntValue:self.openGLView.color.alphaComponent * 100];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)wireFrameChecked:(id)sender {
    if ([sender state] == NSOffState) {
        self.openGLView.SHOW_WIREFRAME = FALSE;
    } else {
        self.openGLView.SHOW_WIREFRAME = TRUE;
    }
}
- (IBAction)showControlPointsChecked:(id)sender {
    self.openGLView.SHOW_CONTROL_POINTS = [sender state] == NSOnState;
}
- (IBAction)shadingSelected:(id)sender {
    switch ([sender selectedRow]) {
        case 0:
            [self.openGLView setShading:NONE];
            break;
        case 1:
            [self.openGLView setShading:PHONG];
            break;
        case 2:
            [self.openGLView setShading:GOURAUD];
            break;
    }
}
- (IBAction)colorSelected:(id)sender {
    self.openGLView.color = [sender color];
}
- (IBAction)transparencyChanged:(id)sender {
    int val = [sender intValue];

    [self.transparencyText setIntValue:val];
    [self.transparencySlider setIntValue:val];

    self.openGLView.color =
        [self.openGLView.color colorWithAlphaComponent:val / 100.0f];
}
- (IBAction)editModeActivated:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    if (clickedSegment == 0) {
        self.openGLView.EDIT_MODE = true;

        [self.openGLView setShading:NONE];
        [self.wireframeCheck setState:NSOnState];
        self.openGLView.SHOW_WIREFRAME      = TRUE;
        self.openGLView.SHOW_CONTROL_POINTS = TRUE;
        [self.showControlPointsCheck setState:NSOnState];
        [self.shadingSelector selectCellAtRow:0 column:0];

        self.generateRandomButton.enabled   = TRUE;
        self.addPointButton.enabled         = TRUE;
        self.deleteSelectedButton.enabled   = TRUE;
        self.wireframeCheck.enabled         = FALSE;
        self.shadingSelector.enabled        = FALSE;
        self.showControlPointsCheck.enabled = FALSE;
    } else {
        self.openGLView.EDIT_MODE           = FALSE;
        self.generateRandomButton.enabled   = FALSE;
        self.addPointButton.enabled         = FALSE;
        self.deleteSelectedButton.enabled   = FALSE;
        self.wireframeCheck.enabled         = TRUE;
        self.shadingSelector.enabled        = TRUE;
        self.showControlPointsCheck.enabled = TRUE;
    }
}
- (IBAction)generateRandomClicked:(id)sender {
    [self.openGLView initExample];
    self.openGLView.UPDATE_NEEDED = TRUE;
}
- (IBAction)deleteSelectedClicked:(id)sender {
}
- (IBAction)addPointClicked:(id)sender {
}
- (IBAction)zoomEntered:(id)sender {
    self.openGLView.zoom = [sender floatValue];
}
- (IBAction)posXEntered:(id)sender {
    self.openGLView.xpos = [sender floatValue];
}
- (IBAction)posYEntered:(id)sender {
    self.openGLView.ypos = [sender floatValue];
}
- (IBAction)posZEntered:(id)sender {
    self.openGLView.zpos = [sender floatValue];
}
- (IBAction)pitchEntered:(id)sender {
    self.openGLView.xrot = [sender floatValue];
}
- (IBAction)yawEntered:(id)sender {
    self.openGLView.yrot = [sender floatValue];
}
- (IBAction)imageViewClicked:(id)sender {
    NSWindow *window   = [self.view window];
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    [panel setAllowedFileTypes:[NSImage imageTypes]];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setMessage:@"Load Map File"];

    [panel beginSheetModalForWindow:window
                  completionHandler:^(NSInteger result) {

                      if (result == NSFileHandlingPanelOKButton) {
                          for (NSURL *url in [panel URLs]) {
                              NSImage *image = [[NSImage alloc]
                                  initWithData:[NSData dataWithContentsOfURL:url]];
                              [self.imageView setImage:image];
                              [self.openGLView setMapFile:url];
                              [self.mappingChooser setEnabled:true forSegment:0];
                              [self.mappingChooser setEnabled:true forSegment:1];
                              [self.mappingChooser setEnabled:true forSegment:2];
                          }
                      }
                  }];
}

- (IBAction)mappingChanged:(id)sender {
    switch ([sender selectedSegment]) {
        case 0:
            [self.openGLView setMapping:COLOR];
            break;
        case 1:
            [self.openGLView setMapping:BUMP];
            break;
        case 2:
            [self.openGLView setMapping:TEXTURE];
            break;
    }
}

@end
