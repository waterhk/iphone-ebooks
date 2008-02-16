// Peekaboo. Uncomment to reveal selectors during runtime
//use 
//:'<,'>s/;/;\r NSLog(@"%s:%d", __FILE__, __LINE__);
//to trace what happens line by line

-(BOOL) respondsToSelector:(SEL)aSelector {

   printf("SELECTOR: %s\n", 

      [NSStringFromSelector(aSelector) UTF8String]);

   return [super respondsToSelector:aSelector];

}
