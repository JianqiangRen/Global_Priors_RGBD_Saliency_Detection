function [A,B,C,d]=Plane_fit_ransac(x,y,z)
    int_point=0;
    try_count=0;
    k=0;
    [~,count_point]=size(x);
    while try_count<100
        while k==0
            point_sel(1)=round(rand(1,1)*count_point);
            point_sel(2)=round(rand(1,1)*count_point);
            point_sel(3)=round(rand(1,1)*count_point);
            if (point_sel(1)~=point_sel(2)) && (point_sel(1)~=point_sel(3)) && (point_sel(3)~=point_sel(2) && (point_sel(1)~=0) && (point_sel(2)~=0) && (point_sel(3)~=0))
                break;
            end
        end
        x_sel=[x(point_sel(1)) x(point_sel(2)) x(point_sel(3))];
        y_sel=[y(point_sel(1)) y(point_sel(2)) y(point_sel(3))];
        z_sel=[z(point_sel(1)) z(point_sel(2)) z(point_sel(3))];
        vector1=[x_sel(2)-x_sel(1) y_sel(2)-y_sel(1) z_sel(2)-z_sel(1)];
        vector2=[x_sel(3)-x_sel(1) y_sel(3)-y_sel(1) z_sel(3)-z_sel(1)];
        norm=cross(vector1,vector2);
        %ensure that norm(1)*(x-x_sel(1))+norm(2)*(y-y_sel(1))+norm(3)*(z-z_sel(1))=0
        for i=1:count_point
            if norm(1)*(x(i)-x_sel(1))+norm(2)*(y(i)-y_sel(1))+norm(3)*(z(i)-z_sel(1))<0.1
                int_point=int_point+1;
            end
        end
        if int_point>count_point/3*2
            A=norm(1);
            B=norm(2);
            C=norm(3);
            d=-(A*x_sel(1)+B*y_sel(1)+C*z_sel(1));
            break;
        end
        int_point=0;
    end
end