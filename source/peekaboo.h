// Peekaboo. Uncomment to reveal selectors during runtime
//use 
//:'<,'>s/;/;\r NSLog(@"%s:%d", __FILE__, __LINE__);
//to trace what happens line by line

-(BOOL) respondsToSelector:(SEL)aSelector {
if (![NSStringFromSelector(aSelector) isEqualToString:@"heartbeatCallback:"])
   GSLog(@"SELECTOR: %s\n", 

      [NSStringFromSelector(aSelector) UTF8String]);

   return [super respondsToSelector:aSelector];

}
- (void)  dumpEvent: ( struct __GSEvent *)  ev
{
	int lIsChording = GSEventIsChordingHandEvent(ev);
	int lClickCount = GSEventGetClickCount(ev);
	CGPoint lLocationInWindow = GSEventGetLocationInWindow(ev);
	float lDeltaX = GSEventGetDeltaX(ev); 
	float lDeltaY = GSEventGetDeltaY(ev); 
	CGPoint lInnerMostPathPosition =  GSEventGetInnerMostPathPosition(ev);
	CGPoint lOuterMostPathPostion = GSEventGetOuterMostPathPosition(ev);
	unsigned int lEventSubType = GSEventGetSubType(ev);
	unsigned int lEventType = GSEventGetType(ev);
	unsigned int lDeviceOrientation = GSEventDeviceOrientation(ev);
	GSLog(@"DUMPEVENT: chording:%d, ClickCount:%d, location.x:%f, location.y:%f, delta.x:%f, delta.y:%f", lIsChording, lClickCount, lLocationInWindow.x, lLocationInWindow.y, lDeltaX, lDeltaY);
	GSLog(@"DUMPEVENT: lInner.x:%f, lInner.y:%f, lOuter.x:%f, lOuter.y:%f, subT:%d, T:%d, orient:%d", lInnerMostPathPosition.x, lInnerMostPathPosition.y, lOuterMostPathPostion.x, lOuterMostPathPostion.y, lEventSubType, lEventType, lDeviceOrientation);
}

