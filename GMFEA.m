function [data_GMFEA] = GMFEA(Tasks,pop,gen,selection_process,rmp,p_il)
%GMFEA function: implementation of MFEA algorithm
% Tasks: Optimization tasks
% pop: population size
% gen: maximum generation
% selection_pressure: choose either 'elitist' or 'roulette wheel'
% rmp: random mating probability
% p_il = 0: probability of individual learning (BFGA quasi-Newton Algorithm).
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
XL = 1:D_multitask;
options = optimoptions(@fminunc,'Display','off','Algorithm','quasi-newton','MaxIter',2);  % settings for individual learning

fnceval_calls = zeros(1,1);
calls_per_individual=zeros(1,pop);
EvBestFitness = zeros(no_of_tasks,gen);    % best fitness found
TotalEvaluations=zeros(gen);               % total number of task evaluations so fer
bestobj=Inf(1,no_of_tasks);
    for i = 1 : pop
        population(i) = Chromosome();
        population(i) = initialize(population(i),D_multitask);
        population(i).skill_factor=0;
    end
    for i = 1 : pop
        [population(i),calls_per_individual(i)] = evaluate(population(i),Tasks,p_il,no_of_tasks,options);
    end
    
    fnceval_calls=fnceval_calls + sum(calls_per_individual);
    TotalEvaluations(1)=fnceval_calls;
    
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
        EvBestFitness(i,1)=bestobj(i);
        bestInd_data(i)=population(1);
        oldbest(i) =bestobj(i);
    end
    for i=1:pop
        [xxx,yyy]=min(population(i).factorial_ranks);
        x=find(population(i).factorial_ranks == xxx);
        equivalent_skills=length(x);
        if equivalent_skills>1
            population(i).skill_factor=x(1+round((equivalent_skills-1)*rand(1)));
            tmp=population(i).factorial_costs(population(i).skill_factor);
            population(i).factorial_costs(1:no_of_tasks)=inf;
            population(i).factorial_costs(population(i).skill_factor)=tmp;
        else
            population(i).skill_factor=yyy;
            tmp=population(i).factorial_costs(population(i).skill_factor);
            population(i).factorial_costs(1:no_of_tasks)=inf;
            population(i).factorial_costs(population(i).skill_factor)=tmp;
        end
    end
    fai = 0.1*gen;
    theta = 0.02*gen;
    topnum = 0.2*pop;
    mean1 = zeros(1,D_multitask);
    mean2 = zeros(1,D_multitask);
    transfer1=zeros(1,D_multitask);    %task1 
    transfer2=zeros(1,D_multitask);    %task2 
    alpha = 0;
    midnum = 0.5*ones(1,D_multitask);
    mu = 10;     % Index of Simulated Binary Crossover (tunable)
    mum = 10;    % Index of polynomial mutation
    generation=1;
    dim1 = D(1);
    dim2 = D(2);
    flag=0;
    if dim1>dim2
        flag=1;
    elseif dim1<dim2
        flag=-1;
    end
    inorder = randperm(D_multitask);
    pop1 = [];
    pop2 = [];
    for i=1:pop
        if  population(i).skill_factor == 1
            pop1 = [pop1;population(i).rnvec];
        else
            pop2 = [pop2;population(i).rnvec];
        end
    end
    pop1_size = size(pop1,1);
    pop2_size = size(pop2,1);
    if flag==1
        index = randi(pop1_size,[pop2_size,1]);
        intpop2 = pop1(index,:);
        intpop2(:,inorder(1:dim2)) = pop2(:,1:dim2);
        kk2=1;
        for i=1:pop
            if  population(i).skill_factor == 2
                population(i).rnvec = intpop2(kk2,:);
                kk2 = kk2+1;
            end
        end
    elseif flag==-1
        index = randi(pop2_size,[pop1_size,1]);
        intpop1 = pop2(index,:);
        intpop1(:,inorder(1:dim1)) = pop1(:,1:dim1);
        kk1=1;
        for i=1:pop
            if  population(i).skill_factor == 1
                population(i).rnvec = intpop1(kk1,:);
                kk1 = kk1+1;
            end
        end
    end
  kk = 1;
    while generation < gen
        generation = generation + 1;
        indorder = randperm(pop);
        count=1;
        if mod(generation,50)==0
           kk = kk+1;
        end
        for i = 1 : pop/2
            p1 = indorder(i);
            p2 = indorder(i+(pop/2));
            child(count)=Chromosome();
            child(count+1)=Chromosome();
            if (population(p1).skill_factor == population(p2).skill_factor)      % crossover
                u = rand(1,D_multitask);
                cf = zeros(1,D_multitask);
                cf(u<=0.5)=(2*u(u<=0.5)).^(1/(mu+1));
                cf(u>0.5)=(2*(1-u(u>0.5))).^(-1/(mu+1));
                population(p1).Trnvec = population(p1).rnvec;
                population(p2).Trnvec = population(p2).rnvec;
                child(count) = crossover(child(count),population(p1),population(p2),cf);    
                child(count+1) = crossover(child(count+1),population(p2),population(p1),cf); 
                child(count).skill_factor=population(p1).skill_factor;
                child(count+1).skill_factor=population(p2).skill_factor;
            elseif rand(1)<rmp
                u = rand(1,D_multitask);
                cf = zeros(1,D_multitask);
                cf(u<=0.5)=(2*u(u<=0.5)).^(1/(mu+1));
                cf(u>0.5)=(2*(1-u(u>0.5))).^(-1/(mu+1));
                if population(p2).skill_factor==2 && population(p1).skill_factor==1
                    population(p1).Trnvec = population(p1).rnvec+transfer1;
                    population(p2).Trnvec = population(p2).rnvec+transfer2;
                    child(count) = crossover(child(count),population(p1),population(p2),cf);
                    child(count+1) = crossover(child(count+1),population(p2),population(p1),cf);
                    child(count).rnvec = child(count).rnvec-transfer1;
                    child(count+1).rnvec = child(count+1).rnvec-transfer2;
                elseif population(p2).skill_factor==1 && population(p1).skill_factor==2
                    population(p1).Trnvec = population(p1).rnvec+transfer2;
                    population(p2).Trnvec = population(p2).rnvec+transfer1;
                    child(count) = crossover(child(count),population(p1),population(p2),cf);
                    child(count+1) = crossover(child(count+1),population(p2),population(p1),cf);
                    child(count).rnvec = child(count).rnvec-transfer2;
                    child(count+1).rnvec = child(count+1).rnvec-transfer1;
                end
                sf1=round(rand(1)+1);
                sf2=round(rand(1)+1);
                if sf1 == 1 % skill factor selection
                    child(count).skill_factor=population(p1).skill_factor;
                else
                    child(count).skill_factor=population(p2).skill_factor;
                end
                
                if sf2 == 1
                    child(count+1).skill_factor=population(p2).skill_factor;
                else
                    child(count+1).skill_factor=population(p1).skill_factor;
                end
            else
                child(count)=mutate(child(count),population(p1),D_multitask,mum);
                child(count).skill_factor=population(p1).skill_factor;
                child(count+1)=mutate(child(count+1),population(p2),D_multitask,mum);
                child(count+1).skill_factor=population(p2).skill_factor;
            end
            count=count+2;
        end
        if flag==1
            for i=1:pop
                if child(i).skill_factor == 2
                    x = child(i).rnvec(inorder(1:dim2));
                    child(i).rnvec(1:dim2) = x;
                end
                if population(i).skill_factor == 2
                    x = population(i).rnvec(inorder(1:dim2));
                    population(i).rnvec(1:dim2) = x;
                end
            end
            intmean2 = mean2(inorder(1:dim2));
            mean2(1:dim2) = intmean2;
        elseif flag==-1
            for i=1:pop
                if child(i).skill_factor == 1
                    x = child(i).rnvec(inorder(1:dim1));
                    child(i).rnvec(1:dim1) = x;
                end
                if population(i).skill_factor == 1
                    x = population(i).rnvec(inorder(1:dim1));
                    population(i).rnvec(1:dim1) = x;
                end
            end
            intmean1 = mean1(inorder(1:dim1));
            mean1(1:dim1) = intmean1;
        end
        for i = 1 : pop
            [child(i),calls_per_individual(i)] = evaluate(child(i),Tasks,p_il,no_of_tasks,options);
        end
        fnceval_calls=fnceval_calls + sum(calls_per_individual);
        TotalEvaluations(generation)=fnceval_calls;
        
        intpopulation(1:pop)=population;
        intpopulation(pop+1:2*pop)=child;
        factorial_cost=zeros(1,2*pop);
        for i = 1:no_of_tasks
            for j = 1:2*pop
                factorial_cost(j)=intpopulation(j).factorial_costs(i);
            end
            [xxx,y]=sort(factorial_cost);
            intpopulation=intpopulation(y);
            for j=1:2*pop
                intpopulation(j).factorial_ranks(i)=j;
            end
            if intpopulation(1).factorial_costs(i)<=bestobj(i)
                bestobj(i)=intpopulation(1).factorial_costs(i);
                bestInd_data(i)=intpopulation(1);
            end
            EvBestFitness(i,generation)=bestobj(i);
            
        end
        for i=1:2*pop
            [xxx,yyy]=min(intpopulation(i).factorial_ranks);
            intpopulation(i).skill_factor=yyy;
            intpopulation(i).scalar_fitness=1/xxx;
        end
        
        if strcmp(selection_process,'elitist')
            [xxx,y]=sort(-[intpopulation.scalar_fitness]);
            intpopulation=intpopulation(y);
            population=intpopulation(1:pop);
        elseif strcmp(selection_process,'roulette wheel')
            for i=1:no_of_tasks
                skill_group(i).individuals=intpopulation([intpopulation.skill_factor]==i);
            end
            count=0;
            while count<pop
                count=count+1;
                skill=mod(count,no_of_tasks)+1;
                population(count)=skill_group(skill).individuals(RouletteWheelSelection([skill_group(skill).individuals.scalar_fitness]));
            end
        end
        inorder = randperm(D_multitask);
        pop1 = [];
        pop2 = [];
        fit1=[];
        fit2=[];
        for i=1:pop
            if  population(i).skill_factor == 1
                pop1 = [pop1;population(i).rnvec];
                fit1=[fit1;population(i).scalar_fitness];
            else
                pop2 = [pop2;population(i).rnvec];
                fit2=[fit2;population(i).scalar_fitness];
            end
        end
        
        if  generation>=fai && mod(generation,theta)==0
            [xxx1,y1]=sort(-fit1);
            [xxx2,y2]=sort(-fit2);
            alpha = (generation/gen)^2;
            mean1 =  mean(pop1(y1(1:topnum),:));   %task1
            mean2 =  mean(pop2(y2(1:topnum),:));   %task2
        end
        pop1_size = size(pop1,1);
        pop2_size = size(pop2,1);
        
        if flag==1
            index = randi(pop1_size,[pop2_size,1]);
            intpop2 = pop1(index,:);
            intpop2(:,inorder(1:dim2)) = pop2(:,1:dim2);
            kk2=1;
            for i=1:pop
                if  population(i).skill_factor == 2
                    population(i).rnvec = intpop2(kk2,:);
                    kk2 = kk2+1;
                end
            end
            intmean2 = mean1;
            intmean2(inorder(1:dim2)) = mean2(1:dim2);
            mean2 = intmean2;
        elseif flag==-1
            index = randi(pop2_size,[pop1_size,1]);
            intpop1 = pop2(index,:);
            intpop1(:,inorder(1:dim1)) = pop1(:,1:dim1);
            kk1=1;
            for i=1:pop
                if  population(i).skill_factor == 1
                    population(i).rnvec = intpop1(kk1,:);
                    kk1 = kk1+1;
                end
            end
            intmean1 = mean2;
            intmean1(inorder(1:dim1)) = mean1(1:dim1);
            mean1 = intmean1;
        end
        transfer1 = alpha*(midnum-mean1);
        transfer2 = alpha*(midnum-mean2);
        disp(['MFEA Generation = ', num2str(generation), ' best factorial costs = ', num2str(bestobj)]);
    end
data_GMFEA.wall_clock_time=toc;
data_GMFEA.EvBestFitness=EvBestFitness;
end
