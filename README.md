# classifyDeferred
This is the code for generating data for classifying a URI-R as either deferred or non-deferred. 
This is meant to create a feature vector (as detailed in the tech report mentioned below) that 
can be put into an ARFF file and used for classification in Weka. Note that we use the interaction.js
file with PhantomJS to generate some of the features (mainly, those that come from the HTTP traffic
of the representation), while the rest come from the DOM only.



Please cite http://arxiv.org/abs/1508.02315. 
