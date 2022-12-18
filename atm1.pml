mtype = {DISPLAY_MAIN_MENU, VALID_CARD, INVALID_CARD, REQUEST_PASSWORD, VERIFY_PW_CON, VERIFY_CARD_CON, REQ_TRANSACTION, REQ_AMT, ATM_PROCESS_TRANS, REQ_CONTINUE, REQ_REMOVE_CARD};  /* ATM action */
mtype = {INSERT_CARD, ENTERED_PASSWORD, CANCEL, WITHDRAW, ENQUIRY, ENTERED_AMT, TOOK_CASH, TERMINATE, CONTINUE, REMOVED_CARD};  
mtype = {VERIFY_PW_BANK, VERIFY_CARD_BANK, CORRECT_PW, INCORRECT_PW, DORMANT_CARD,ACTIVE_CARD,CONSORTIUM_PROCESS_TRANS, TRANSACTION_SUCCESS, TRANSACTION_UNSUCCESS};  
mtype = {VERIFIED_PW, WRONG_PW, VERIFIED_CARD, WRONG_CARD, BANK_TRANS_SUCCESS, BANK_TRANS_FAIL, ANOTHER_TRANSACTION, END_TRANSACTION}; 

chan user2atm = [1] of {mtype};
chan atm2user = [1] of {mtype};
chan atm2consortium = [1] of {mtype};
chan consortium2atm = [1] of {mtype};
chan consortium2bank = [1] of {mtype};
chan bank2consortium = [1] of {mtype};

bool user_cancel = false;
bool password_correct = false;
bool withdraw_selected = false;
bool enquiry_selected = false;
bool receipt_printed = false; 
bool card_ejected = false;
bool cash_dispensed = false;
bool transaction_success = false;
bool amount_entered = false;
bool continue_transaction = true;
bool active_card = true;

proctype Consortium(){
	printf("initiating Consortium Process...\n"); 
	
	VerifyPassword:
	if
	:: atm2consortium?VERIFY_PW_CON -> 
			printf("Consortium Process: consortium verifying acc with bank...\n"); 
			consortium2bank!VERIFY_PW_BANK;
			if
			:: bank2consortium?VERIFIED_PW -> 
					consortium2atm!CORRECT_PW; 
					printf("Consortium Process: consortium verified acc: correct password...\n"); 
					goto ProcessTransaction;
			:: bank2consortium?WRONG_PW -> 
					consortium2atm!INCORRECT_PW; 
					printf("Consortium Process: consortium verified acc: incorrect password...\n"); 
					goto VerifyPassword
			fi;
	
	:: atm2consortium?END_TRANSACTION -> 
			consortium2bank!END_TRANSACTION;
			goto end;
	fi;

	/* VerifyCard:
	if
	:: atm2consortium?VERIFY_CARD_CON ->
			consortium2bank!VERIFY_CARD_BANK;
			if
			:: bank2consortium?VERIFIED_CARD ->
					consortium2atm!ACTIVE_CARD;
					goto ProcessTransaction;
			:: bank2consortium?WRONG_CARD ->
					consortium2atm!DORMANT_CARD;
					goto end
			fi;
	:: atm2consortium?END_TRANSACTION -> 
			consortium2bank!END_TRANSACTION;
			goto end;
	fi;
	*/

	ProcessTransaction:
	if
	:: atm2consortium?ATM_PROCESS_TRANS -> 
			printf("Consortium Process: consortium process transaction...\n"); 
			consortium2bank!CONSORTIUM_PROCESS_TRANS;
			if
			:: bank2consortium?BANK_TRANS_SUCCESS -> 
					consortium2atm!TRANSACTION_SUCCESS; 
					printf("Consortium Process: consortium processed transaction successfully...\n"); 
			:: bank2consortium?BANK_TRANS_FAIL -> 
					consortium2atm!TRANSACTION_UNSUCCESS; 
					printf("Consortium Process: transaction failed...\n"); 
			fi;
	
	:: atm2consortium?END_TRANSACTION -> 
			consortium2bank!END_TRANSACTION;
			goto end;
	fi;
	if
	:: atm2consortium?ANOTHER_TRANSACTION ->
			consortium2bank!ANOTHER_TRANSACTION;
			goto ProcessTransaction;
	:: atm2consortium?END_TRANSACTION -> 
			consortium2bank!END_TRANSACTION;
			goto end;
	fi;

	end:
		printf("Consortium Process: ending ...\n"); 
}

proctype Bank(){
	printf("initiating Bank Process...\n"); 
	
	VerifyPassword:
	if
	::  consortium2bank?VERIFY_PW_BANK -> 
		printf("Bank Process: bank verifying password...\n"); 
		if
		:: 	bank2consortium!VERIFIED_PW; 
			printf("Bank Process: bank verified acc...\n"); 
			goto ProcessTransaction;
		::	bank2consortium!WRONG_PW; 
			printf("Bank Process: wrong password, authentication fails...\n"); 
			goto VerifyPassword;
		fi;
	:: consortium2bank?END_TRANSACTION -> goto end;
	fi;

	
	/* VerifyCard:
	if
	::  consortium2bank?VERIFY_CARD_BANK -> 
		printf("Bank Process: bank verifying card...\n"); 
		if
		:: 	bank2consortium!VERIFIED_CARD; 
			printf("Bank Process: bank verified card...\n"); 
			goto ProcessTransaction;
		::	bank2consortium!WRONG_CARD; 
			printf("Bank Process: wrong card, authentication fails...\n"); 
			goto end;
		fi;
	:: consortium2bank?END_TRANSACTION -> goto end;
	fi;
    */
	
	ProcessTransaction:
	if
	:: consortium2bank?CONSORTIUM_PROCESS_TRANS -> 
		printf("Bank Process: bank process transaction...\n"); 
		
		if
		:: 	bank2consortium!BANK_TRANS_SUCCESS; 
			printf("Bank Process: bank transaction succesful...\n"); 
		::	bank2consortium!BANK_TRANS_FAIL; 
			printf("Bank Process: bank transaction fail...\n"); 
		fi;
	:: consortium2bank?END_TRANSACTION -> goto end;	
	fi;
	
	if
	:: consortium2bank?ANOTHER_TRANSACTION -> goto ProcessTransaction;
	:: consortium2bank?END_TRANSACTION -> goto end;	
	fi;
	
	end:
		printf("Bank Process: ending ...\n"); 
}
	
proctype User(){	
	printf("initiating User Process...\n"); 

	InsertCard:
	atm2user?DISPLAY_MAIN_MENU;
	printf("User Process: user inserting card...\n"); 
	user2atm!INSERT_CARD; 
	if
	:: 	atm2user?VALID_CARD ->
			goto EnterPassword;
	:: 	atm2user?INVALID_CARD ->
			goto RemoveCard;
	fi;	
	
	EnterPassword:
	atm2user?REQUEST_PASSWORD;
	if
	::	printf("User Process: user entered password...\n"); 
		user2atm!ENTERED_PASSWORD; 
		if 	
		::	atm2user?CORRECT_PW ->
				goto EnterSelection;
		::	atm2user?INCORRECT_PW ->
				goto RemoveCard;
		fi;
	:: 	printf("User Process: user cancel transactions...\n"); 
		user2atm!CANCEL;
		goto RemoveCard;
	fi;


	Checking:
	if
	:: user2atm!ACTIVE_CARD ->
			goto EnterSelection;
	::  atm2user?DORMANT_CARD ->
	        goto RemoveCard;
    fi;

	EnterSelection:
	atm2user?REQ_TRANSACTION;
	if
	:: 	printf("User Process: user select withdrawal...\n"); 
		user2atm!WITHDRAW; 
		atm2user?REQ_AMT;
		if
		::	printf("User Process: user enter withdrawal amt...\n"); 
			user2atm!ENTERED_AMT; 
		
			if
			:: 	atm2user?TRANSACTION_SUCCESS ->
					printf("User Process: user take cash...\n"); 
					user2atm!TOOK_CASH; 
					goto Terminate;
			::	atm2user?TRANSACTION_UNSUCCESS ->
					goto Terminate;
			fi;
		::	printf("User Process: user cancel transactions...\n"); 
			user2atm!CANCEL;
			goto RemoveCard;
		fi;
	
	:: 	printf("User Process: user select enquiry...\n"); 
		user2atm!ENQUIRY;
		
		if
		:: 	atm2user?TRANSACTION_SUCCESS ->
				printf("User Process: user view amount in bank...\n");
				goto Terminate;
		::	atm2user?TRANSACTION_UNSUCCESS ->
				goto Terminate;
		fi;
	:: 	printf("User Process: user cancel transactions...\n"); 
		user2atm!CANCEL;
		goto RemoveCard;
	fi;

	Terminate:
	atm2user?REQ_CONTINUE;
	if
	::	printf("User Process: user choose not continue with another transaction...\n"); 
		user2atm!TERMINATE; 
		goto RemoveCard;
	::	printf("User Process: user choose to continue with another transaction...\n");
		user2atm!CONTINUE;
		goto EnterSelection;
	fi;

	RemoveCard:
	atm2user?REQ_REMOVE_CARD -> 
		printf("User Process: user remove card...\n"); 
		user2atm!REMOVED_CARD;
}

proctype ATM(){	
	printf("initiating ATM Process...\n");
	
	DisplayMenuState:
	atm2user!DISPLAY_MAIN_MENU ->
		printf("ATM Process: Main Menu...\n");
	user2atm?INSERT_CARD -> 
		goto ReadCardState;
	
	ReadCardState:
	if
	:: 	printf("ATM Process: Card is valid...\n");  
		atm2user!VALID_CARD;
		printf("ATM Process: Prompt user for password...\n");  
		atm2user!REQUEST_PASSWORD;
		goto ReceiveAccState;
	:: 	printf("ATM Process: Card is unreadable...\n");  
		atm2user!INVALID_CARD;
		atm2user!REQ_REMOVE_CARD;
		goto EjectCardState;
	fi;

	ReceiveAccState:
	if
	:: user2atm?ENTERED_PASSWORD -> 
			printf("ATM Process: ATM verifying password with consortium...\n"); 
			atm2consortium!VERIFY_PW_CON;
			user_cancel = false;
			goto VerifyAccState;
	:: user2atm?CANCEL -> 
			printf("ATM Process: User cancel transaction. Eject card. ...\n");
			atm2user!REQ_REMOVE_CARD;
			user_cancel = true;
			goto EjectCardState;
	fi;
	
	VerifyAccState:
	if
	:: consortium2atm?CORRECT_PW -> 
			atm2user!CORRECT_PW;
			printf("ATM Process: password is verified by consortium\n "); 
			password_correct = true;
			goto ReqTransactionState;
	:: consortium2atm?INCORRECT_PW	-> 			
			printf("ATM Process: password is incorrect\n"); 
			atm2user!INCORRECT_PW;
			password_correct = false;
			goto PrintReceiptState;
	fi;


/*
	CheckingCardState:
	if
	:: consortium2atm?DORMANT_CARD ->
			atm2user!DORMANT_CARD;
			active_card = false;
			goto EjectCardState;
	:: consortium2atm?ACTIVE_CARD ->
			active_card = true;
			atm2user!REQ_TRANSACTION;
			goto ReqTransactionState;
	fi;
	*/
	CheckingCardState:
	if
	:: printf("ATM Process: Card is valid...\n");  
		atm2user!ACTIVE_CARD;
		printf("ATM Process: ...\n");  
		goto ReceiveAccState;
	:: 	printf("ATM Process: Card is unreadable...\n");  
		atm2user!DORMANT_CARD;
		atm2user!REQ_REMOVE_CARD;
		goto EjectCardState;
	fi;
	
	VerifyAccState:
	if
	:: consortium2atm?CORRECT_PW -> 
			atm2user!CORRECT_PW;
			printf("ATM Process: password is verified by consortium\n "); 
			password_correct = true;
			atm2user!REQ_TRANSACTION;
			printf("ATM Process: Prompt user to enter in the transaction type\n "); 
			goto ReqTransactionState;
	:: consortium2atm?INCORRECT_PW	-> 			
			printf("ATM Process: password is incorrect\n"); 
			atm2user!INCORRECT_PW;
			password_correct = false;
			goto Ipsd2;
	fi;
	
    Ipsd2:
    if
    :: consortium2atm?CORRECT_PW ->
			atm2user!REQ_TRANSACTION;
			printf("ATM Process: Prompt user to enter in the transaction type\n "); 
			goto ReqTransactionState;
	:: consortium2atm?INCORRECT_PW	-> 			
			printf("ATM Process: password is incorrect\n"); 
			atm2user!INCORRECT_PW;
			password_correct = false;
			goto Ipsd3;
	fi;

	Ipsd3:

	if
	:: consortium2atm?CORRECT_PW ->
    		atm2user!CORRECT_PW;
			printf("ATM Process: password is verified by consortium\n "); 
			password_correct = true;
			atm2user!REQ_TRANSACTION;
			printf("ATM Process: Prompt user to enter in the transaction type\n "); 
			goto ReqTransactionState;
	:: consortium2atm?INCORRECT_PW	-> 			
			printf("ATM Process: password is incorrect\n"); 
			atm2user!INCORRECT_PW;
			password_correct = false;
			goto Card_Taken;
	fi;

	ReqTransactionState:
	if
	:: user2atm?CANCEL -> 
			printf("ATM Process: User cancel transaction. Eject card. ...\n");
					atm2user!REQ_REMOVE_CARD;
					user_cancel = true;
					goto EjectCardState;
	:: user2atm?WITHDRAW -> 
			printf("ATM Process: Prompt user for withdrawal amt...\n"); 
			atm2user!REQ_AMT;
			withdraw_selected = true;
			enquiry_selected = false;
			user_cancel = false;
			goto ReqAmtState;
	:: user2atm?ENQUIRY -> 
			printf("ATM Process: Prompt user for withdrawal amt...\n"); 
			atm2consortium!ATM_PROCESS_TRANS;
			withdraw_selected = false;
			enquiry_selected = true;
			user_cancel = false;
			goto EnquiryTransactionState;
	fi;
	
	ReqAmtState:
	if
	:: user2atm?CANCEL -> 
			printf("ATM Process: User cancel transaction. Eject card. ...\n");
			atm2user!REQ_REMOVE_CARD;
			user_cancel = true;
			amount_entered = false;
			goto EjectCardState;
	:: user2atm?ENTERED_AMT -> 
			printf("ATM Process: process withdrawal transaction...\n"); 
			atm2consortium!ATM_PROCESS_TRANS;
			user_cancel = false;
			amount_entered = true;
			goto WithdrawalTransactionState;
	fi;
	
	WithdrawalTransactionState:
	if
	:: consortium2atm?TRANSACTION_SUCCESS	-> 			
			printf("ATM Process: Dispense cash. Prompt user to take cash...\n"); 
			atm2user!TRANSACTION_SUCCESS;
			transaction_success = true;
			goto CashDispenseState;
	:: consortium2atm?TRANSACTION_UNSUCCESS	-> 			
			printf("ATM Process: Bank transaction failed\n"); 
			atm2user!TRANSACTION_UNSUCCESS;
			atm2user!REQ_CONTINUE;
			transaction_success = false;
			goto ReqContinueState;
	fi;
	
	EnquiryTransactionState:
	if
	:: consortium2atm?TRANSACTION_SUCCESS	-> 			
			printf("ATM Process: Display amt to user...\n"); 
			atm2user!TRANSACTION_SUCCESS;
			atm2user!REQ_CONTINUE;
			transaction_success = true;
			goto ReqContinueState;
	:: consortium2atm?TRANSACTION_UNSUCCESS	-> 			
			printf("ATM Process: Bank transaction failed\n"); 
			atm2user!TRANSACTION_UNSUCCESS;
			atm2user!REQ_CONTINUE;
			transaction_success = false;
			goto ReqContinueState;
	fi;
	

	CashDispenseState:
	user2atm?TOOK_CASH -> 
			printf("ATM Process: Prompt user to continue with another transaction or terminate the transaction...\n"); 
			atm2user!REQ_CONTINUE;
			assert(password_correct);
			assert(!user_cancel);
			assert(withdraw_selected);
			assert(!enquiry_selected);
			assert(transaction_success);
			assert(amount_entered);
			cash_dispensed = true;
			goto ReqContinueState;
	
	ReqContinueState:

    /* to model single transaction mode */
	
	/* 
	continue_transaction = false;
	goto PrintReceiptState;
	*/


	/* to model continuous transaction mode  */
 	if
	:: user2atm?TERMINATE -> 
			continue_transaction = false;
			goto PrintReceiptState;
	:: user2atm?CONTINUE -> 
			printf("ATM Process: Redirect user to select transaction type...\n"); 
			atm2user!REQ_TRANSACTION;
			atm2consortium!ANOTHER_TRANSACTION;
			continue_transaction = true;
			goto ReqTransactionState;
	fi;
/**/

	PrintReceiptState:
	printf("ATM Process: print receipt ...\n");
	atm2user!REQ_REMOVE_CARD;
	receipt_printed = true;
	goto EjectCardState;
	

	EjectCardState:
	printf("ATM Process: eject card...\n");
	card_ejected = true;
	user2atm?REMOVED_CARD;
	atm2consortium!END_TRANSACTION;
}

/*  ltl property1 { !([](cash_dispensed  -> <> card_ejected)) }     */
  /*  ltl property2 { !([](withdraw_selected && transaction_success -> <> cash_dispensed)) } */
   /* ltl property3 { !([]!(!password_correct && cash_dispensed)) }  */
   *  ltl property2 { !([](withdraw_selected && transaction_success -> <> cash_dispensed)) } */
  /* ltl property3 { !([](!active_card -> <> (card_ejected))) } */


init {	
	
	atomic {
	run ATM();
	run User();
	run Consortium();
	run Bank();
	}
	
	 

}


