package com.example;

import com.salesforce.functions.jvm.sdk.Context;
import com.salesforce.functions.jvm.sdk.InvocationEvent;
import com.salesforce.functions.jvm.sdk.SalesforceFunction;
import com.salesforce.functions.jvm.sdk.data.Record;

import java.util.ArrayList;
import java.util.List;

/**
 * Describe ExampleFunction here.
 */
public class ExampleFunction implements SalesforceFunction<FunctionInput, FunctionOutput> {

  @Override
  public FunctionOutput apply(InvocationEvent<FunctionInput> event, Context context)
      throws Exception {

    List<Account> accounts = new ArrayList<>();

    return new FunctionOutput(accounts);
  }
}
