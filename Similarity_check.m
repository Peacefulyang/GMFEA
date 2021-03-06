function Rs = Similarity_check(Tasks,pop,gen,selection_process,rmp,p_il,reps)
%MFEA function: implementation of MFEA algorithm
    clc    
    tic       
    if mod(pop,2) ~= 0
        pop = pop + 1;
    end   
    no_of_tasks=length(Tasks);
    if no_of_tasks <= 1
        error('At least 2 tasks required for MFEA');
    end
    D=zeros(1,no_of_tasks);
    for i=1:no_of_tasks
        D(i)=Tasks(i).dims;
    end
    D_multitask=max(D);
    options = optimoptions(@fminunc,'Display','off','Algorithm','quasi-newton','MaxIter',2);  % settings for individual learning
    
    fnceval_calls = zeros(1,reps);  
    calls_per_individual=zeros(1,pop);
    EvBestFitness = zeros(no_of_tasks*reps,gen);    % best fitness found
    TotalEvaluations=zeros(reps,gen);               % total number of task evaluations so fer
    bestobj=Inf(1,no_of_tasks);
    for rep = 1:reps
        disp(rep)
        for i = 1 : pop
            population(i) = Chromosome();
            population(i) = initialize(population(i),D_multitask);
            population(i).skill_factor=0;
        end
        for i = 1 : pop
            [population(i),calls_per_individual(i)] = evaluate(population(i),Tasks,p_il,no_of_tasks,options);
        end

        fnceval_calls(rep)=fnceval_calls(rep) + sum(calls_per_individual);
        TotalEvaluations(rep,1)=fnceval_calls(rep);

        factorial_cost=zeros(1,pop);
        for i = 1:no_of_tasks
            for j = 1:pop
                factorial_cost(j)=population(j).factorial_costs(i);
            end
            [xxx,y]=sort(factorial_cost);
            population=population(y);
            for j=1:pop
                population(j).factorial_ranks(i)=j; 
            end
            bestobj(i)=population(1).factorial_costs(i);
            EvBestFitness(i+2*(rep-1),1)=bestobj(i);
            bestInd_data(rep,i)=population(1);
        end
        s1=[];
        X=[];
        Y=[];
        for i = 1:pop
                        s1(i) = (population(i).factorial_ranks(1)-population(i).factorial_ranks(2));
%             X(i) = population(i).factorial_costs(1);
%             Y(i) = population(i).factorial_costs(2);
        end
        s1 = 6*sum(s1.^2);
        Rs = 1-s1/(pop^3-pop);
%         coeff = corr(X' , Y' , 'type' , 'Spearman');  
%             Rs = mySpearman(X , Y);
    end
end