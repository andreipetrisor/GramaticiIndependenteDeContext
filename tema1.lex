%top{
#include <iostream>
#include <stdio.h>
#include <vector>
#include <map>
#include <string>
#include <algorithm>  

using namespace std;

#define lastchar yytext[yyleng - 1]

vector<char> neterminal;
vector<char> v;
vector<char> alfa;
vector<char> repl;
vector<char> act;
multimap<char, vector<char> > rules;
char start;
char cale;
int ok = 0;
}


lower-case [a-d]|[f-z]
special "'"|"-"|"="|"["|"]"|";"|"`"|"\\"|"."|"/"|"~"|"!"|"@"|"#"|"$"|"%"|"^"|"&"|"*"|"_"|"+"|":"|"\""|"|"|"<"|">"|"?"
digit [0-9]
terminal {lower-case}|{special}|{digit}
alfabet {terminal}+?
word "e"|{terminal}+
non1terminal {nonterminal}|{terminal}
nonterminal [A-Z]
prodRules {prodRule}+?
replacement "e"|{non1terminal}+
start [A-Z]
whitespace [ \t\r\n]*

%s SIM SEP ALFA ALFAB ALFABE ALFABET SEPA RULES SEPR1 START STARTSIM RULE RULER SEPR2 SEPR3 FINISH SEPR4 SEPR5

/* Stari:
	**SIM: Citeste un (non)terminal din V
	**SEP: Citeste separatorul din V sau ca s-a terminat V
	**ALFA: Citeste separatorul intre alfabet si multimea V
	**ALFAB: Citeste separatorul de terminare de alfabet sau un caracter din alfabet
	**ALFABE: Citeste separatorul dintre elemente din aflabet sau simbolul de terminare a alfabetului
	**ALFABET: Citeste urmatorul terminal din alfabet
	**SEPA: Citeste separatorul din alfabet sau ca s-a terminat de citit din alfabet
	**RULES: Citeste separatorul dintre alfabet si setul de reguli
	**SEPR1: Citeste simbolul de inchidere a setului de reguli, daca acesta este gol sau citeste inceputul, simbolul "("
	**RULE: Citeste partea stanga a regulii
	**SEPR2: Citeste separatorul dntre partea stanga si cea dreapta
	**RULER: Citeste partea dreapta a regulii
	**SEPR3: Citeste simbolul ce marecheaza inchiderea regulii
	**SEPR4: Citeste separatorul dintre reguli sau simbolul ce marcheaza inchiderea regulilor
	**SEPR5: Citeste simbolul ce marcheaza inceperea unei noi reguli
	**START: Citeste separatorul dintre setul de reguli si simbolul de start
	**STARTSIM: Citeste simbolul de start
	**FINISH: Citeste ultima paranteza cu care se termina fisierul
*/

%%
<INITIAL>{whitespace}"("{whitespace}"{"{whitespace} {BEGIN(SIM);}

<SIM>{non1terminal} {v.push_back(lastchar);
			BEGIN(SEP);
}
<SEP>{
	{whitespace}","{whitespace} BEGIN(SIM);
	{whitespace}"}"{whitespace} BEGIN(ALFA);
}

<ALFA>{whitespace}","{whitespace}"{"{whitespace} {BEGIN(ALFAB);}
<ALFAB>{
		{whitespace}"}"{whitespace} BEGIN(RULES);	
		{terminal} alfa.push_back(lastchar); BEGIN(ALFABE);
}	
<ALFABE>{
		{whitespace}","{whitespace} BEGIN(ALFABET);
		{whitespace}"}"{whitespace} BEGIN(RULES);
}

<ALFABET>{terminal} { alfa.push_back(lastchar);
					  BEGIN(SEPA);
}
<SEPA>{
		{whitespace}","{whitespace} BEGIN(ALFABET);
		{whitespace}"}"{whitespace} BEGIN(RULES);
}

<RULES>{whitespace}","{whitespace}"{"{whitespace} {BEGIN(SEPR1);}
<SEPR1>{ 
		{whitespace}"}"{whitespace} BEGIN(START);
		{whitespace}"("{whitespace} BEGIN(RULE);
}
<RULE>{nonterminal} { cale = lastchar;
					  BEGIN(SEPR2);
}
<SEPR2>{whitespace}","{whitespace} { act.clear();
									BEGIN(RULER);
}
<RULER>{replacement} { int i = 0;
						for(i = 0; i < yyleng; i++)
							act.push_back(yytext[i]);
         				rules.insert(pair<char, vector<char> >(cale, act));
                        BEGIN(SEPR3);
} 
<SEPR3>{whitespace}")"{whitespace} {BEGIN(SEPR4);}
<SEPR4>{ 
		{whitespace}","{whitespace} BEGIN(SEPR5);
		{whitespace}"}"{whitespace} BEGIN(START);
}
<SEPR5>{whitespace}"("{whitespace} {BEGIN(RULE);}


<START>{whitespace}","{whitespace} {BEGIN(STARTSIM);}
<STARTSIM>{start} { start = lastchar;
					BEGIN(FINISH);
}
<FINISH>{whitespace}")"{whitespace} {;}

. {
	fprintf(stderr, "Syntax error\n");
	ok = 1;
	return 0;
	
}
%%

int main(int argc, char* argv[])
{	
	//verificam numarul argumentelor
	if(argc != 2)
	{	fprintf(stderr, "Argument error\n");
		return 0;
	}
	//verificam daca este corect argumentul
	if(strcmp(argv[1], "--is-void") != 0 && strcmp(argv[1], "--has-e") != 0 && strcmp(argv[1], "--useless-nonterminals") != 0)
	{
		fprintf(stderr, "Argument error\n");
		return 0;
	}

	//dechis fisierul
	FILE* f = fopen("grammar", "rt");
	
	yyrestart(f);
	yylex();

	//daca nu avem erori de sintaxa
	if(ok!=1)
	{	
		int i = 0;
		int count = 0;
		//verific cate elemente din V sunt in alfabet
		for(i = 0; i < v.size(); i++)
		{	
			if(find(alfa.begin(), alfa.end(), v[i])!= alfa.end())
				count++;
			else	
				if(v[i] < 'A' || v[i] > 'Z')
				{
					fprintf(stderr, "Semantic error\n");
					return 0;			
				}
				else {
					neterminal.push_back(v[i]);
				}
		}

		//daca nu se afla toate in alfabet
		if(count < alfa.size())
		{
			fprintf(stderr, "Semantic error\n");
			return 0;			
		}

		//daca simbolul de start nu se afla printre neterminali
		if(find(neterminal.begin(), neterminal.end(), start) == neterminal.end())
		{	
			fprintf(stderr, "Semantic error\n");
			return 0;			
		}			

		multimap<char, vector<char> >::iterator it = rules.begin();
 		while(it != rules.end())
  		{   
  			//daca in partea stanga a regulilor nu avem doar un neterminal
			if(find(neterminal.begin(), neterminal.end(), it->first) == neterminal.end())
			{ 
				fprintf(stderr, "Semantic error\n");
				return 0;			
			}
			
			for(i = 0; i < (it->second).size(); i++)
			{	
				//daca in partea dreapta aveam vreaun simbol care nu se afla in multimea V
				if(find(v.begin(), v.end(), (it->second)[i]) == v.end() && (it->second)[i] != 'e')				
				{	
					fprintf(stderr, "Semantic error\n");
					return 0;			
				}
			}
    		it++;
  		}


  		vector<char> marcati;
  		int j = 0;

		while(true)
		{
			int size_marcati = marcati.size();
			it = rules.begin();
 			while(it != rules.end())
  			{
  				//daca nu este marcat
				if(find(marcati.begin(), marcati.end(), it->first) == marcati.end())
				{	int nr= 0;
					//vedem sa fie compus doar din terminali sau nonterminali marcati 
					for(i = 0; i < (it->second).size(); i++)
					{	//daca se gaseste in alfabet sau daca sunt unul este e sau daca este noterminal marcat
						if(find(alfa.begin(), alfa.end(), (it->second)[i]) != alfa.end() || (it->second)[i] == 'e' || find(marcati.begin(), marcati.end(), (it->second)[i]) != marcati.end())				
						{
							nr++;
						}
					}
					//daca sunt doar terminali sau neterminali utili in partea dreapta a regulii
					if(nr == (it->second).size())
						marcati.push_back(it->first);
				}
    			it++;
  			}
  			if(size_marcati == marcati.size())
  				break;
		}
  		//useless-non-terminals
  		if(strcmp(argv[1], "--useless-nonterminals") == 0)
  		{  		
  			for(i = 0; i < v.size(); i++)
  			{	//afisam nonterminali inutili
  				if(v[i] >= 'A' && v[i] <= 'Z' && find(marcati.begin(), marcati.end(), v[i]) == marcati.end())
  				printf("%c\n", v[i]);
  			}

  		}

  		//is-void
   		if(strcmp(argv[1], "--is-void") == 0)
  		{	
  			//daca simbolul de start este inutil
  			if(find(marcati.begin(), marcati.end(), start) == marcati.end())
  				printf("Yes\n");
  			else
  				printf("No\n");
  		}

  		//has-e
   		if(strcmp(argv[1], "--has-e") == 0)
  		{
  			//resetam vectorul marcati
	  		marcati.clear();
	  		int j = 0;
			while(true)
			{	
				int size_marcati = marcati.size();
				it = rules.begin();
	 			
	 			while(it != rules.end())
	  			{
	  				//daca nu este marcat
					if(find(marcati.begin(), marcati.end(), it->first) == marcati.end())
					{	
						int nr= 0;
						for(i = 0; i < (it->second).size(); i++)
						{	//daca este 'e' sau daca este neterminal marcat
							if((it->second)[i] == 'e' || find(marcati.begin(), marcati.end(), (it->second)[i]) != marcati.end())				
							{	
								nr++;
							}

						}
						//toti din dreapta sunt neterminali marcati sau 'e'
						if(nr == (it->second).size())
							marcati.push_back(it->first);
					}
	    			it++;
	  			}
	  			if(size_marcati == marcati.size())
	  				break;
			}

			//daca simbolul de start este marcat
			if(find(marcati.begin(), marcati.end(), start) != marcati.end())
			{
				printf("Yes\n");
			}
			else 
				printf("No\n");
  		}


	}

	fclose(f);
	return 0;
}
