//
//  getMov.swift
//
//  Created by 안병욱 on 2023/01/30.
// 검색창

import SwiftUI

struct getMov: View {
    
    @State var respo = [Movie]() // 무비 데이터
    @State var inputValue = "" // 검색어
    @State var isresultsEmpty = false // 검색 결과
    @Environment(\.dismiss) private var dismiss // 커스텀 Back 버튼 Back 변수
    @State var genreSelected = false
    
    @State var RandomGenre = Set<String>()
    @State var GenreRArray = [String]()
    @State var movieTotal: Int = 0
    @State var skip = 0
    
    @StateObject var movieFunction = MovieFunction()
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack{
                if movieFunction.searchSuccess {
                    VStack{}.onAppear(){ // 뷰에서 클로져 실행 위해 임시 뷰 그리고 뷰가 그려질 경우 실행할 클로져.
                        let response = movieFunction.searchResponse!
                        self.movieTotal = response.total
                        
                        // 검색 결과로 영화가 10개 보다 많으면 데이터를 배열에 추가
                        if 0 < skip && respo.count < self.movieTotal {
                            self.respo.append(contentsOf: response.data)
                            
                        // 검색 결과가 10개 보다 적으면 배열 대체
                        } else {
                            self.respo = response.data
                        }
                        print("\(respo.count), \(response.total)")
                        movieFunction.searchSuccess = false // 임시 VStack 삭제용.
                    }
                }
                if movieFunction.allGenreSuccess {
                    VStack{}.onAppear(){
                        //검색 장르 6개 가져옴.
                        let response = movieFunction.genreResponse!
                        while RandomGenre.count != 6 {
                            
                            // 장르가 서버에서 데이터를 가져오면 \n이 들어있어 뷰가 이상하게 그려지고 동일항 장르 전시 됨.
                            // trimmingCharacters 로 \n을 제거
                            let str = response.data.randomElement()!.trimmingCharacters(in: ["\n"])
                            RandomGenre.insert(str)
                        }
                        GenreRArray.append(contentsOf: Array(RandomGenre))
                        movieFunction.allGenreSuccess = false
                    }
                }
                VStack(spacing: 0){
                    HStack{
                        //커스텀 Back 버튼
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.white)
                                .padding(10)
                        }

                        border(geometry)
                            .padding(10)
                    }
                    //MARK: 검색어 추천
                    if respo.isEmpty{
                        genreRecommand(geometry)
                            .onAppear(){
                                movieFunction.totalGenre()
                            }
                    }
                // 검색 결과 있으면 리스트 그림.
                    if !isresultsEmpty {
                        //MARK: 리스트
                        ScrollView{
                            LazyVStack(alignment: .leading){
                                ForEach(respo, id: \._id) { Rdata in
                                    NavigationLink(destination: detailView(_id: Rdata._id)){
                                        HStack{
                                            AsyncImage(url: URL(string: "http://mynf.codershigh.com:8080\(Rdata.image ?? "")")){ img in
                                                img
                                                    .resizable()
                                                    .scaledToFill()
                                                    //.aspectRatio(contentMode: .fill)
                                                    .frame(width: 100/1.47,height: 100)
                                                    .clipped()
                                            } placeholder: {
                                                Rectangle()
                                                    .cornerRadius(10)
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 100/sqrt(2),height: 100)
                                            }
                                            .padding(.leading)
                                            VStack(alignment: .leading){
                                                Text(Rdata.title)
                                                    .font(.title2)
                                                    .bold()
                                                    .padding(.bottom, 5)
                                                HStack{
                                                    // 장르가 \n이 있는 동일한 장르 \n 제거
                                                    ForEach(Rdata.genre , id: \.self){ genre in
                                                        if Rdata.genre.last == genre {
                                                            Text(genre.trimmingCharacters(in: ["\n"]))
                                                        } else {
                                                            Text(genre.trimmingCharacters(in: ["\n"])+",")
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(5)
                                                .foregroundColor(.white)
                                                Spacer()
                                        }//.frame(width: geometry.size.width)
                                    }
                                    .preferredColorScheme(.dark)
                                    
                                }
                                
                                .ignoresSafeArea(.all, edges: .bottom)
                                .background(.black)
                                if self.movieTotal != respo.count{
                                    //MARK: 더 많은 데이터 로딩
                                    // 아래 이미지 나타나면 데이터 가져옴.
                                    Image(systemName: "chevron.compact.down")
                                        .onAppear(){
                                            self.skip = respo.count
                                            movieFunction.GetResponse(inputs: inputValue, skip: self.skip)
                                            print("버튼 실행함")
                                        }
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .frame(width: geometry.size.width)
                                }
                            }
                        }
                        
                        
                // 검색 결과 검색 결과 없음 전시
                    } else {
                        Text("\n검색 결과 없음.")
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .background(.black)
                
            }
        }.preferredColorScheme(.dark)
        .toolbar(.hidden)
    }
    
    //MARK: SearchBar
    func border( _ geometry: GeometryProxy) -> some View {
        ZStack{
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 40)
                //.padding(.trailing,-5)
                .foregroundColor(Color(UIColor(red: 67/255, green: 66/255, blue: 66/255, alpha: 1)))
            HStack{
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
                TextField( "", text: $inputValue)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
                    .modifier(PlaceholderStyle(showPlaceHolder: inputValue.isEmpty, placeholder: "장르 검색", color: Color.gray))
                //.background(.red)
                    .onSubmit {
                        self.skip = 0
                        movieFunction.GetResponse(inputs: inputValue, skip: skip)
                    }
                if !inputValue.isEmpty {
                    Button {
                        inputValue = ""
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.white)
                            .padding(.trailing, 10)
                    }

                }
                    
            }
            .padding(.leading, 10)
            //.frame(width: geometry.size.width - 100)
        }
    }
    
    //MARK: 장르 추천 뷰
    func genreRecommand(_ geometry: GeometryProxy) -> some View {
        HStack{
            VStack{
                ForEach(0..<GenreRArray.count/2, id: \.self) { i in
                    Button {
                        inputValue = GenreRArray[i]
                        self.skip = 0
                            movieFunction.GetResponse(inputs: GenreRArray[i], skip: skip)
                    } label: {
                        Text(GenreRArray[i])
                            .font(.title3)
                            .lineLimit(1)
                            .padding(10)
                    }
                }.frame(width: geometry.size.width/2)
            }
            VStack{
                ForEach(GenreRArray.count/2..<GenreRArray.count, id: \.self) { i in
                    Button {
                        self.skip = 0
                            movieFunction.GetResponse(inputs: GenreRArray[i], skip: skip)
                    } label: {
                        Text(GenreRArray[i])
                            .font(.title3)
                            .padding(10)
                            .lineLimit(1)
                    }
                }.frame(width: geometry.size.width/2)
            }
        }
    }
}


struct getMov_Previews: PreviewProvider {
    static var previews: some View {
        getMov()
    }
}
